import sys
import os
import numpy as np
import VNet as VN

basePath=os.getcwd()

params = dict()
params['DataManagerParams']=dict()
params['ModelParams']=dict()

#params of the algorithm
params['ModelParams']['numcontrolpoints']=2
params['ModelParams']['sigma']=15
params['ModelParams']['device']=0
params['ModelParams']['prototxtTrain']=os.path.join(basePath,'Prototxt/train_noPooling_ResNet_cinque.prototxt')
params['ModelParams']['prototxtTest']=os.path.join(basePath,'Prototxt/test_noPooling_ResNet_cinque.prototxt')
params['ModelParams']['snapshotON']=86000
params['ModelParams']['snapshotOFF']=94000
params['ModelParams']['snapshotONOFF']=118000

params['ModelParams']['dirTrainOFF']=os.path.join(basePath,'Dataset/Train/OFF')
params['ModelParams']['dirTrainON']=os.path.join(basePath,'Dataset/Train/ON')
params['ModelParams']['dirTest']=os.path.join(basePath,'Dataset/TBP')
params['ModelParams']['dirResult']=os.path.join(basePath,'ResultsON') #where we need to save the results (relative to the base path)
params['ModelParams']['dirResult2']=os.path.join(basePath,'ResultsOFF') #where we need to save the results (relative to the base path)
params['ModelParams']['dirResult3']=os.path.join(basePath,'ResultsONOFF') #where we need to save the results (relative to the base path)
params['ModelParams']['dirSnapshotsON']=os.path.join(basePath,'Models/SnapshotsON/') #where to save the models while training
params['ModelParams']['dirSnapshotsOFF']=os.path.join(basePath,'Models/SnapshotsOFF/') #where to save the models while training
params['ModelParams']['dirSnapshotsONOFF']=os.path.join(basePath,'Models/SnapshotsONOFF/') #where to save the models while training

params['ModelParams']['batchsize'] = 1  #the batchsize
params['ModelParams']['numIterations'] = 100000 #the number of iterations
params['ModelParams']['baseLR'] = 0.001 #the learning rate, initial one
params['ModelParams']['nProc'] = 1 #the number of threads to do data augmentation

#params of the DataManager
params['DataManagerParams']['dstRes'] = np.asarray([1,1,1.5],dtype=float)
params['DataManagerParams']['VolSize'] = np.asarray([128,128,64],dtype=int)
params['DataManagerParams']['normDir'] = False #if rotates the volume according to its transformation in the mhd file. Not reccommended.

model=VN.VNet(params)
trainON = [i for i, j in enumerate(sys.argv) if j == '-trainON']
if len(trainON)>0:
    model.trainON()

trainOFF = [i for i, j in enumerate(sys.argv) if j == '-trainOFF']
if len(trainOFF)>0:
    model.trainOFF()

test = [i for i, j in enumerate(sys.argv) if j == '-test']  #####ON
if len(test) > 0:
    model.test()

test2 = [i for i, j in enumerate(sys.argv) if j == '-test2'] ##########OFF
if len(test2) > 0:
    model.test2()

test3 = [i for i, j in enumerate(sys.argv) if j == '-test3'] ##########ON and OFF
if len(test3) > 0:
    model.test3()
