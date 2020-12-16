import cv2
import matplotlib.pyplot as plt
import numpy as np
import sys

import skimage.measure
from skimage import data
from skimage.util import img_as_ubyte
from skimage.filters.rank import entropy
from skimage.morphology import disk

from matplotlib import cm
import scipy.io as spio

mat = spio.loadmat('datagip.mat', squeeze_me=True)

gip_data = mat['a'].T
video_path = './Video/'
video_output_path = './Output_GIP/'
video_name = 'DOWNTOWN DAY.mp4'

square_size = 5
thickness = 5

if len(sys.argv) <= 1:
    print("not enough arguments")
    video_name = input("Please specify the video name:")
    #exit(0)
else:
    video_name = sys.argv[1]

# Create a VideoCapture object and read from input file
# If the input is the camera, pass 0 instead of the video file name
cap = cv2.VideoCapture(video_path + video_name)
timestamps = [cap.get(cv2.CAP_PROP_POS_MSEC)]

# Check if camera opened successfully
if (cap.isOpened() == False):
    print("Error opening video stream or file")
frame_rate = int(cap.get(cv2.CAP_PROP_FPS))
frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

target_width = int(frame_width)
target_height = int(frame_height)

save_width = int(frame_width)
save_height = int(frame_height)

#'F','M','P','4'
#'H','E','V','C'
#'X','2','6','4'
#'D', 'I', 'V', 'X'
out = cv2.VideoWriter(video_output_path + video_name, cv2.VideoWriter_fourcc('F','M','P','4'), frame_rate, (save_width, save_height), True)

print(target_width)
print(target_height)

index = 0
# Read until video is completed
while cap.isOpened():
    # Capture frame-by-frame
    ret, frame = cap.read()
    if ret == True:
        timestamp = cap.get(cv2.CAP_PROP_POS_MSEC)/1000.0
        
        # locate the time
        while gip_data[index][0] + 0.00001 < timestamp:
            index += 1
        
        # pick x and y
        x_norm = gip_data[index][1]
        y_norm = gip_data[index][2]
        
        # scale
        x = int(x_norm * frame_width)
        y = int(y_norm * frame_height)
        
        # process the frame
        cv2.rectangle(frame, (x - square_size, y - square_size), (x + square_size, y+square_size), (255,0,0), thickness)
        # Display the resulting frame
        cv2.imshow('Frame', frame)
        out.write(frame)

        # Press Q on keyboard to  exit
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    
    # Break the loop
    else:
        break

# When everything done, release the video capture object
cap.release()
out.release()

# Closes all the frames
cv2.destroyAllWindows()
