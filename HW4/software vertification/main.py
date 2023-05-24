# -*- coding: utf-8 -*-
"""
Created on Sun May 21 20:40:31 2023

@author: PCUSER
"""

from PIL import Image
import numpy as np
from fxpmath import Fxp
from skimage.measure import block_reduce

def resized_gray(img):
    resized_img = img.resize((64, 64), Image.BILINEAR)
    return np.asarray(resized_img.convert('L'))

def conv(img_array, kernel, stride=1, dilation=2):
    padded_image = np.pad(img_array, ((2, 2), (2, 2)), mode='edge')
    output = np.zeros_like(img_array).astype(np.float32)
    for i in range(0, img_array.shape[0], stride):
        for j in range(0, img_array.shape[1], stride):
            output[i, j] = np.sum(padded_image[i:i+5:2, j:j+5:2] * kernel)
    layer0_output = np.maximum(output+bias, 0)
    return layer0_output
    
def max_pool(img_array):
    block_size = (2, 2)
    output = block_reduce(img_array, block_size, np.max)
    layer1_output = np.ceil(output)
    return layer1_output

def output(img_array, filename):
    img_fixed = Fxp(img_array, signed=True, n_word=13, n_frac=4)
    dat = open(f"{filename}.dat", "w")
    i = 0
    for col in img_fixed:
        for data in col:
            dat.write(f"{data.bin()} //data {i}: {data}\n")
            i=i+1
    dat.close()
    img = Image.fromarray(img_array.astype(np.uint8))
    img.save(f"{filename}.png")

if __name__ == "__main__":
    path = "C:/Users/PCUSER/Desktop/DIC/DIC_HW/hw4/file/images/lenna.png"
    img = Image.open(path)
    kernel = np.array(
            [[-0.0625, -0.125, -0.0625], 
            [-0.25, 1, -0.25],
            [-0.0625, -0.125, -0.0625]]).astype(np.float32)
    bias = -0.75
    
    resized_gray_img = resized_gray(img)
    output(resized_gray_img, "img")
    
    layer0_golden = conv(resized_gray_img, kernel, stride=1, dilation=2)
    output(layer0_golden, "layer0_golden")

    layer1_golden = max_pool(layer0_golden)
    output(layer1_golden, "layer1_golden")

    

    