#  Copyright 2023 Google LLC

#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at

#       https://www.apache.org/licenses/LICENSE-2.0

#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

"""A pipeline that uses RunInference API to perform image classification."""

# standard libraries
import io
import os
from typing import Iterable, Iterator, Optional, Tuple, Union

# third party libraries
import apache_beam as beam
import numpy as np
import torch
import torch.nn as nn
from apache_beam.io.filesystems import FileSystems
from apache_beam.ml.inference.base import KeyedModelHandler, PredictionResult, RunInference
from apache_beam.ml.inference.pytorch_inference import PytorchModelHandlerTensor
from apache_beam.ml.inference.tensorflow_inference import TFModelHandlerTensor
from PIL import Image
from torchvision import models, transforms

import tensorflow as tf  # isort:skip

# config helper functions

import re
from enum import Enum

# third party libraries
from pydantic import BaseModel, Field, root_validator, validator


class ModelName(str, Enum):
    RESNET101 = "resnet101"
    MOBILENET_V2 = "mobilenet_v2"


class ModelConfig(BaseModel):
    model_state_dict_path: str = Field(None, description="path that contains the torch model state directory")
    model_class_name: ModelName = Field(None, description="Reference to the class definition of the model.")
    model_params: dict = Field(
        None,
        description="Parameters passed to the constructor of the model_class. "
        "These will be used to instantiate the model object in the RunInference API.",
    )
    tf_model_uri: str = Field(None, description="TF model uri from https://tfhub.dev/")
    device: str = Field("CPU", description="Device to be used on the Runner. Choices are (CPU, GPU)")
    min_batch_size: int = 10
    max_batch_size: int = 100

    @root_validator
    def validate_fields(cls, values):
        v = values.get("model_state_dict_path")
        if v and values.get("tf_model_uri"):
            raise ValueError("Cannot specify both model_state_dict_path and tf_model_uri")
        if v is None and values.get("tf_model_uri") is None:
            raise ValueError("At least one of model_state_dict_path or tf_model_uri must be specified")
        if v and values.get("model_class_name") is None:
            raise ValueError("model_class_name must be specified when using model_state_dict_path")
        if v and values.get("model_params") is None:
            raise ValueError("model_params must be specified when using model_state_dict_path")
        return values


def _validate_topic_path(topic_path):
    pattern = r"projects/.+/topics/.+"
    return bool(re.match(pattern, topic_path))


class SourceConfig(BaseModel):
    input: str = Field(..., description="the input path to a text file or a Pub/Sub topic")
    images_dir: str = Field(
        None,
        description="Path to the directory where images are stored."
        "Not required if image names in the input file have absolute path.",
    )
    streaming: bool = False

    @validator("streaming", pre=True, always=True)
    def set_streaming(cls, v, values):
        return _validate_topic_path(values["input"])


class SinkConfig(BaseModel):
    output: str = Field(..., description="the output path to save results as a text file")


def get_model_class(model_name: ModelName) -> nn.Module:
    model_dict = {ModelName.RESNET101: models.resnet101, ModelName.MOBILENET_V2: models.mobilenet_v2}

    model_class = model_dict.get(model_name)
    if not model_class:
        raise ValueError(f"cannot recognize the model {model_name}")
    return model_class


def read_image(image_file_name: Union[str, bytes], path_to_dir: Optional[str] = None) -> Tuple[str, Image.Image]:
    if isinstance(image_file_name, bytes):
        image_file_name = image_file_name.decode()
    if path_to_dir is not None:
        image_file_name = os.path.join(path_to_dir, image_file_name)
    with FileSystems().open(image_file_name, "r") as file:
        data = Image.open(io.BytesIO(file.read())).convert("RGB")
        return image_file_name, data


def preprocess_image(data: Image.Image) -> torch.Tensor:
    image_size = (224, 224)
    # Pre-trained PyTorch models expect input images normalized with the
    # below values (see: https://pytorch.org/vision/stable/models.html)
    normalize = transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    transform = transforms.Compose(
        [
            transforms.Resize(image_size),
            transforms.ToTensor(),
            normalize,
        ]
    )
    return transform(data)


def preprocess_image_for_tf(data: Image.Image) -> tf.Tensor:
    # Convert the input image to the type and dimensions required by the model.

    img = data.resize((224, 224))
    img = np.array(img) / 255.0

    return tf.cast(tf.convert_to_tensor(img[...]), dtype=tf.float32)


def filter_empty_lines(text: str) -> Iterator[str]:
    if len(text.strip()) > 0:
        yield text


class PostProcessor(beam.DoFn):
    def process(self, element: Tuple[str, PredictionResult]) -> Iterable[str]:
        filename, prediction_result = element
        if isinstance(prediction_result.inference, torch.Tensor):
            prediction = torch.argmax(prediction_result.inference, dim=0)
        else:
            prediction = np.argmax(prediction_result.inference)
        yield filename + "," + str(prediction.item())


def build_pipeline(pipeline, source_config: SourceConfig, sink_config: SinkConfig, model_config: ModelConfig) -> None:
    """
    Args:
      pipeline: a given input pipeline
      source_config: a source config
      sink_config: a sink config
      model_config: a model config to instantiate PytorchModelHandlerTensor
    """

    # In this example we pass keyed inputs to RunInference transform.
    # Therefore, we use KeyedModelHandler wrapper over PytorchModelHandler or TFModelHandlerTensor.
    if model_config.model_state_dict_path:
        model_handler = KeyedModelHandler(
            PytorchModelHandlerTensor(
                state_dict_path=model_config.model_state_dict_path,
                model_class=get_model_class(model_config.model_class_name),
                model_params=model_config.model_params,
                device=model_config.device,
                min_batch_size=model_config.min_batch_size,
                max_batch_size=model_config.max_batch_size,
            )
        )
    elif model_config.tf_model_uri:
        model_handler = KeyedModelHandler(
            TFModelHandlerTensor(
                model_uri=model_config.tf_model_uri,
                device=model_config.device,
                min_batch_size=model_config.min_batch_size,
                max_batch_size=model_config.max_batch_size,
            )
        )
    else:
        raise ValueError("Only support PytorchModelHandler and TFModelHandlerTensor!")

    if source_config.streaming:
        # read the text file path from Pub/Sub and use FixedWindows to group these images
        # and then run the model inference and store the results into GCS
        filename_value_pair = (
            pipeline
            | "ReadImageNamesFromPubSub" >> beam.io.ReadFromPubSub(topic=source_config.input)
            | "Window into fixed intervals" >> beam.WindowInto(beam.window.FixedWindows(60 * 5))
            | "ReadImageData" >> beam.Map(lambda image_name: read_image(image_file_name=image_name))
        )
    else:
        # read the text file and create the pair of input data with the file name and its image
        filename_value_pair = (
            pipeline
            | "ReadImageNames" >> beam.io.ReadFromText(source_config.input)
            | "FilterEmptyLines" >> beam.ParDo(filter_empty_lines)
            | "ReadImageData"
            >> beam.Map(lambda image_name: read_image(image_file_name=image_name, path_to_dir=source_config.images_dir))
        )

    if model_config.model_state_dict_path:
        filename_value_pair = filename_value_pair | "PreprocessImages" >> beam.MapTuple(
            lambda file_name, data: (file_name, preprocess_image(data))
        )
    else:
        filename_value_pair = filename_value_pair | "PreprocessImages_TF" >> beam.MapTuple(
            lambda file_name, data: (file_name, preprocess_image_for_tf(data))
        )

    # do the model inference and postprocessing
    predictions = (
        filename_value_pair
        | "RunInference" >> RunInference(model_handler)
        | "ProcessOutput" >> beam.ParDo(PostProcessor())
    )

    # combine all the window results into one text for GCS
    if source_config.streaming:
        (
            predictions
            | "WriteOutputToGCS"
            >> beam.io.fileio.WriteToFiles(sink_config.output, shards=0)  # pylint: disable=expression-not-assigned
        )
    else:
        # save the predictions to a text file
        predictions | "WriteOutputToGCS" >> beam.io.WriteToText(  # pylint: disable=expression-not-assigned
            sink_config.output, shard_name_template="", append_trailing_newlines=True
        )