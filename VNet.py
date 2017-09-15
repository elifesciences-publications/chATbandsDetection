import caffe
import numpy as np
#import matplotlib.pyplot as plt
#import matplotlib
import os
import DataManager as DM
import utilities
from os.path import splitext
from multiprocessing import Process, Queue
import time
from skimage import io
import SimpleITK as sitk
from os.path import isfile, join
class VNet(object):
    params=None
    dataManagerTrain=None
    dataManagerTest=None

    def __init__(self,params):
        self.params=params
        caffe.set_device(self.params['ModelParams']['device'])
        caffe.set_mode_gpu()

    def prepareDataThread(self, dataQueue, numpyImages, numpyGT):

        nr_iter = self.params['ModelParams']['numIterations']
        batchsize = self.params['ModelParams']['batchsize']

        keysIMG = numpyImages.keys()

        nr_iter_dataAug = nr_iter*batchsize
        np.random.seed()
        whichDataList = np.random.randint(len(keysIMG), size=int(nr_iter_dataAug/self.params['ModelParams']['nProc']))
        whichDataForMatchingList = np.random.randint(len(keysIMG), size=int(nr_iter_dataAug/self.params['ModelParams']['nProc']))

        for whichData,whichDataForMatching in zip(whichDataList,whichDataForMatchingList):
            filename, ext = splitext(keysIMG[whichData])

            currGtKey = filename + '_segmentation' + ext
            currImgKey = filename + ext

            # data agugumentation through hist matching across different examples...
            ImgKeyMatching = keysIMG[whichDataForMatching]

            defImg = numpyImages[currImgKey]
            defLab = numpyGT[currGtKey]
          #  print "is image binary:"
          #  print ((defLab.astype(int)==0) | (defLab.astype(int)==1)).all()
            defImg = utilities.hist_match(defImg, numpyImages[ImgKeyMatching])

            if(np.random.rand(1)[0]>0.5): #do not apply deformations always, just sometimes
                defImg, defLab = utilities.produceRandomlyDeformedImage(defImg, defLab,
                                    self.params['ModelParams']['numcontrolpoints'],
                                               self.params['ModelParams']['sigma'])

            weightData = np.zeros_like(defLab,dtype=float)
            weightData[defLab == 1] = np.prod(defLab.shape) / np.sum((defLab==1).astype(dtype=np.float32))
            weightData[defLab == 0] = np.prod(defLab.shape) / np.sum((defLab == 0).astype(dtype=np.float32))

            dataQueue.put(tuple((defImg,defLab, weightData)))

    def trainThread(self,dataQueue,solver):

        nr_iter = self.params['ModelParams']['numIterations']
        batchsize = self.params['ModelParams']['batchsize']

        batchData = np.zeros((batchsize, 1, self.params['DataManagerParams']['VolSize'][0], self.params['DataManagerParams']['VolSize'][1], self.params['DataManagerParams']['VolSize'][2]), dtype=float)
        batchLabel = np.zeros((batchsize, 1, self.params['DataManagerParams']['VolSize'][0], self.params['DataManagerParams']['VolSize'][1], self.params['DataManagerParams']['VolSize'][2]), dtype=float)

        #only used if you do weighted multinomial logistic regression
        batchWeight = np.zeros((batchsize, 1, self.params['DataManagerParams']['VolSize'][0],
                               self.params['DataManagerParams']['VolSize'][1],
                               self.params['DataManagerParams']['VolSize'][2]), dtype=float)

        train_loss = np.zeros(nr_iter)
        for it in range(nr_iter):
            for i in range(batchsize):
                [defImg, defLab, defWeight] = dataQueue.get()

                batchData[i, 0, :, :, :] = defImg.astype(dtype=np.float32)
                batchLabel[i, 0, :, :, :] = (defLab > 0.5).astype(dtype=np.float32)
                batchWeight[i, 0, :, :, :] = defWeight.astype(dtype=np.float32)
		
            solver.net.blobs['data'].data[...] = batchData.astype(dtype=np.float32)
            solver.net.blobs['label'].data[...] = batchLabel.astype(dtype=np.float32)
            #solver.net.blobs['labelWeight'].data[...] = batchWeight.astype(dtype=np.float32)
            #use only if you do softmax with loss
         #   print "check label if binary"
         #   l = batchLabel.astype(int)
	 #   print ((l == 0)|(l==1)).all()		
	 #   print "iter " + str(it)	
            solver.step(1)
	   # print "backward"
	   # solver.net.backward()
           # print "update"		
	   	
		  # this does the training
            train_loss[it] = solver.net.blobs['loss'].data
		
 #           if (np.mod(it, 10) == 0):
 #               plt.clf()
 #               plt.plot(range(0, it), train_loss[0:it])
 #               plt.pause(0.00000001)
 #           matplotlib.pyplot.show()
	#solver.net.save('/home/Desktop/VNet/Models/vnet.caffemodel')

    def trainON(self):
        print self.params['ModelParams']['dirTrainON']

        #we define here a data manage object
        self.dataManagerTrain = DM.DataManager(self.params['ModelParams']['dirTrainON'],
                                               self.params['ModelParams']['dirResult'],
                                               self.params['DataManagerParams'])
	print "load train data"
        self.dataManagerTrain.loadTrainingData() #loads in sitk format

        howManyImages = len(self.dataManagerTrain.sitkImages)
        howManyGT = len(self.dataManagerTrain.sitkGT)

        assert howManyGT == howManyImages

        print "The dataset has shape: data - " + str(howManyImages) + ". labels - " + str(howManyGT)
	time.sleep(1)
        test_interval = 50000
        # Write a temporary solver text file because pycaffe is stupid
        with open("solver.prototxt", 'w') as f:
            f.write("net: \"" + self.params['ModelParams']['prototxtTrain'] + "\" \n")
            f.write("base_lr: " + str(self.params['ModelParams']['baseLR']) + " \n")
            f.write("momentum: 0.99 \n")
            f.write("weight_decay: 0.0005 \n")
            f.write("lr_policy: \"step\" \n")
            f.write("stepsize: 30000 \n")
            f.write("gamma: 0.1 \n")
            f.write("display: 1 \n")
            f.write("snapshot: 500 \n")
            f.write("snapshot_prefix: \"" + self.params['ModelParams']['dirSnapshotsON'] + "\" \n")
            #f.write("test_iter: 3 \n")
            #f.write("test_interval: " + str(test_interval) + "\n")

        f.close()
        solver = caffe.SGDSolver("solver.prototxt")
        os.remove("solver.prototxt")

        if (self.params['ModelParams']['snapshotON'] > 0):
            solver.restore(self.params['ModelParams']['dirSnapshotsON'] + "_iter_" + str(
                self.params['ModelParams']['snapshotON']) + ".solverstate")

  #      plt.ion()

        numpyImages = self.dataManagerTrain.getNumpyImages()
        numpyGT = self.dataManagerTrain.getNumpyGT()

        #numpyImages['Case00.mhd']
        #numpy images is a dictionary that you index in this way (with filenames)

        for key in numpyImages:
            mean = np.mean(numpyImages[key][numpyImages[key]>0])
            std = np.std(numpyImages[key][numpyImages[key]>0])

            numpyImages[key]-=mean
            numpyImages[key]/=std

        dataQueue = Queue(30) #max 50 images in queue
        dataPreparation = [None] * self.params['ModelParams']['nProc']
	print "creating thread"
        #thread creation
        for proc in range(0,self.params['ModelParams']['nProc']):
            dataPreparation[proc] = Process(target=self.prepareDataThread, args=(dataQueue, numpyImages, numpyGT))
            dataPreparation[proc].daemon = True
            dataPreparation[proc].start()

        self.trainThread(dataQueue, solver)

    def trainOFF(self):
        print self.params['ModelParams']['dirTrainOFF']

        #we define here a data manage object
        self.dataManagerTrain = DM.DataManager(self.params['ModelParams']['dirTrainOFF'],
                                               self.params['ModelParams']['dirResult2'],
                                               self.params['DataManagerParams'])
	print "load train data"
        self.dataManagerTrain.loadTrainingData() #loads in sitk format

        howManyImages = len(self.dataManagerTrain.sitkImages)
        howManyGT = len(self.dataManagerTrain.sitkGT)

        assert howManyGT == howManyImages

        print "The dataset has shape: data - " + str(howManyImages) + ". labels - " + str(howManyGT)
	time.sleep(1)
        test_interval = 50000
        # Write a temporary solver text file because pycaffe is stupid
        with open("solver.prototxt", 'w') as f:
            f.write("net: \"" + self.params['ModelParams']['prototxtTrain'] + "\" \n")
            f.write("base_lr: " + str(self.params['ModelParams']['baseLR']) + " \n")
            f.write("momentum: 0.99 \n")
            f.write("weight_decay: 0.0005 \n")
            f.write("lr_policy: \"step\" \n")
            f.write("stepsize: 30000 \n")
            f.write("gamma: 0.1 \n")
            f.write("display: 1 \n")
            f.write("snapshot: 500 \n")
            f.write("snapshot_prefix: \"" + self.params['ModelParams']['dirSnapshotsOFF'] + "\" \n")
            #f.write("test_iter: 3 \n")
            #f.write("test_interval: " + str(test_interval) + "\n")

        f.close()
        solver = caffe.SGDSolver("solver.prototxt")
        os.remove("solver.prototxt")

        if (self.params['ModelParams']['snapshotOFF'] > 0):
            solver.restore(self.params['ModelParams']['dirSnapshotsOFF'] + "_iter_" + str(
                self.params['ModelParams']['snapshotOFF']) + ".solverstate")

  #      plt.ion()

        numpyImages = self.dataManagerTrain.getNumpyImages()
        numpyGT = self.dataManagerTrain.getNumpyGT()

        #numpyImages['Case00.mhd']
        #numpy images is a dictionary that you index in this way (with filenames)

        for key in numpyImages:
            mean = np.mean(numpyImages[key][numpyImages[key]>0])
            std = np.std(numpyImages[key][numpyImages[key]>0])

            numpyImages[key]-=mean
            numpyImages[key]/=std

        dataQueue = Queue(30) #max 50 images in queue
        dataPreparation = [None] * self.params['ModelParams']['nProc']
	print "creating thread"
        #thread creation
        for proc in range(0,self.params['ModelParams']['nProc']):
            dataPreparation[proc] = Process(target=self.prepareDataThread, args=(dataQueue, numpyImages, numpyGT))
            dataPreparation[proc].daemon = True
            dataPreparation[proc].start()

        self.trainThread(dataQueue, solver)

    def test(self):
        self.dataManagerTest = DM.DataManager(self.params['ModelParams']['dirTest'], self.params['ModelParams']['dirResult'], self.params['DataManagerParams'])
        self.dataManagerTest.loadTestData()

        net = caffe.Net(self.params['ModelParams']['prototxtTest'],
                        os.path.join(self.params['ModelParams']['dirSnapshotsON'],"_iter_" + str(self.params['ModelParams']['snapshotON']) + ".caffemodel"),
                        caffe.TEST)

        numpyImages = self.dataManagerTest.getNumpyImages()
#        originNumpy = self.dataManagerTest.getNumpyImages()
        for key in numpyImages:
            mean = np.mean(numpyImages[key][numpyImages[key]>0])
            std = np.std(numpyImages[key][numpyImages[key]>0])

            numpyImages[key] -= mean
            numpyImages[key] /= std

        results = dict()

        for key in numpyImages:

            btch = np.reshape(numpyImages[key],[1,1,numpyImages[key].shape[0],numpyImages[key].shape[1],numpyImages[key].shape[2]])
            net.blobs['data'].data[...] = btch
	    print numpyImages[key].shape	
            out = net.forward()
            l = out["labelmap"]
            print l.shape
            labelmap = np.squeeze(l[0,1,:,:,:])
	    res = np.squeeze(labelmap)
	    res = np.transpose(res, [2, 1,0])
	    res = np.transpose(res, [1,0,2])		
            w = sitk.ImageFileWriter()
	    filename,ext = splitext(key)
	    
	  #  io.imsave("/home/quan/Desktop/VNet/Results/" + filename + "_rotate" + ext,np.squeeze(res))	
           # w.Execute(labelmap)
         #   results[key] = np.squeeze(labelmap)
	 #   print "write result"	
	 #   toWrite = sitk.GetImageFromArray(results[key],isVector=False)
#	    toWrite = sitk.Cast(toWrite, sitk.sitkUInt8)
            writer = sitk.ImageFileWriter()
         #   filename, ext = splitext(key)
            writer.SetFileName(os.path.join(self.params['ModelParams']['dirResult'],filename + "_rotate" + ext))
           # writer.SetFileName("/home/quan/Desktop/VNet/ResultsON/" + filename + "_rotate" + ext)
         #   writer.Execute(toWrite)
	 #   original = np.squeeze(oribatch[0,0,:,:,:])
            im2 = sitk.GetImageFromArray(np.squeeze(res), isVector=False)
	    im2 = sitk.Cast(sitk.RescaleIntensity(im2), sitk.sitkUInt8)
        #    writer.SetFileName("/home/quan/Desktop/VNet/TrainResult/" + filename + "_original" + ext)
            writer.Execute(im2)
        #    mean = np.squeeze(btch[0,0,:,:,:])
        #    toW = sitk.GetImageFromArray(mean, isVector=False)
        #    toW = sitk.Cast(toW, sitk.sitkUInt16)
        #    writer.SetFileName("/home/quan/Desktop/VNet/Results6/" + filename + "_mean" + ext)
         #   writer.Execute(toW)

	
         #   self.dataManagerTest.writeResultsFromNumpyLabel(np.squeeze(labelmap),key)

    def test2(self):
        self.dataManagerTest = DM.DataManager(self.params['ModelParams']['dirTest'], self.params['ModelParams']['dirResult2'], self.params['DataManagerParams'])
        self.dataManagerTest.loadTestData()

        net = caffe.Net(self.params['ModelParams']['prototxtTest'],
                        os.path.join(self.params['ModelParams']['dirSnapshotsOFF'],"_iter_" + str(self.params['ModelParams']['snapshotOFF']) + ".caffemodel"),
                        caffe.TEST)

        numpyImages = self.dataManagerTest.getNumpyImages()
#        originNumpy = self.dataManagerTest.getNumpyImages()
        for key in numpyImages:
            mean = np.mean(numpyImages[key][numpyImages[key]>0])
            std = np.std(numpyImages[key][numpyImages[key]>0])

            numpyImages[key] -= mean
            numpyImages[key] /= std

        results = dict()

        for key in numpyImages:

            btch = np.reshape(numpyImages[key],[1,1,numpyImages[key].shape[0],numpyImages[key].shape[1],numpyImages[key].shape[2]])
            net.blobs['data'].data[...] = btch
	    print numpyImages[key].shape	
            out = net.forward()
            l = out["labelmap"]
            print l.shape
            labelmap = np.squeeze(l[0,1,:,:,:])
	    res = np.squeeze(labelmap)
	    res = np.transpose(res, [2, 1,0])
	    res = np.transpose(res, [1,0,2])		
            w = sitk.ImageFileWriter()
	    filename,ext = splitext(key)
	    
	  #  io.imsave("/home/quan/Desktop/VNet/Results/" + filename + "_rotate" + ext,np.squeeze(res))	
           # w.Execute(labelmap)
         #   results[key] = np.squeeze(labelmap)
	 #   print "write result"	
	 #   toWrite = sitk.GetImageFromArray(results[key],isVector=False)
#	    toWrite = sitk.Cast(toWrite, sitk.sitkUInt8)
            writer = sitk.ImageFileWriter()
         #   filename, ext = splitext(key)
            writer.SetFileName(os.path.join(self.params['ModelParams']['dirResult2'],filename + "_rotate" + ext))
         #   writer.Execute(toWrite)
	 #   original = np.squeeze(oribatch[0,0,:,:,:])
            im2 = sitk.GetImageFromArray(np.squeeze(res), isVector=False)
	    im2 = sitk.Cast(sitk.RescaleIntensity(im2), sitk.sitkUInt8)
        #    writer.SetFileName("/home/quan/Desktop/VNet/TrainResult/" + filename + "_original" + ext)
            writer.Execute(im2)
        #    mean = np.squeeze(btch[0,0,:,:,:])
        #    toW = sitk.GetImageFromArray(mean, isVector=False)
        #    toW = sitk.Cast(toW, sitk.sitkUInt16)
        #    writer.SetFileName("/home/quan/Desktop/VNet/Results6/" + filename + "_mean" + ext)
         #   writer.Execute(toW)

	
         #   self.dataManagerTest.writeResultsFromNumpyLabel(np.squeeze(labelmap),key)

    def test3(self):
        self.dataManagerTest = DM.DataManager(self.params['ModelParams']['dirTest'], self.params['ModelParams']['dirResult3'], self.params['DataManagerParams'])
        self.dataManagerTest.loadTestData()

        net = caffe.Net(self.params['ModelParams']['prototxtTest'],
                        os.path.join(self.params['ModelParams']['dirSnapshotsONOFF'],"_iter_" + str(self.params['ModelParams']['snapshotONOFF']) + ".caffemodel"),
                        caffe.TEST)

        numpyImages = self.dataManagerTest.getNumpyImages()
#        originNumpy = self.dataManagerTest.getNumpyImages()
        for key in numpyImages:
            mean = np.mean(numpyImages[key][numpyImages[key]>0])
            std = np.std(numpyImages[key][numpyImages[key]>0])

            numpyImages[key] -= mean
            numpyImages[key] /= std

        results = dict()

        for key in numpyImages:

            btch = np.reshape(numpyImages[key],[1,1,numpyImages[key].shape[0],numpyImages[key].shape[1],numpyImages[key].shape[2]])
            net.blobs['data'].data[...] = btch
	    print numpyImages[key].shape	
            out = net.forward()
            l = out["labelmap"]
            print l.shape
            labelmap = np.squeeze(l[0,1,:,:,:])
	    res = np.squeeze(labelmap)
	    res = np.transpose(res, [2, 1,0])
	    res = np.transpose(res, [1,0,2])		
            w = sitk.ImageFileWriter()
	    filename,ext = splitext(key)
	    
	  #  io.imsave("/home/quan/Desktop/VNet/Results/" + filename + "_rotate" + ext,np.squeeze(res))	
           # w.Execute(labelmap)
         #   results[key] = np.squeeze(labelmap)
	 #   print "write result"	
	 #   toWrite = sitk.GetImageFromArray(results[key],isVector=False)
#	    toWrite = sitk.Cast(toWrite, sitk.sitkUInt8)
            writer = sitk.ImageFileWriter()
         #   filename, ext = splitext(key)
            writer.SetFileName(os.path.join(self.params['ModelParams']['dirResult3'],filename + "_rotate" + ext))
         #   writer.Execute(toWrite)
	 #   original = np.squeeze(oribatch[0,0,:,:,:])
            im2 = sitk.GetImageFromArray(np.squeeze(res), isVector=False)
	    im2 = sitk.Cast(sitk.RescaleIntensity(im2), sitk.sitkUInt8)
        #    writer.SetFileName("/home/quan/Desktop/VNet/TrainResult/" + filename + "_original" + ext)
            writer.Execute(im2)
        #    mean = np.squeeze(btch[0,0,:,:,:])
        #    toW = sitk.GetImageFromArray(mean, isVector=False)
        #    toW = sitk.Cast(toW, sitk.sitkUInt16)
        #    writer.SetFileName("/home/quan/Desktop/VNet/Results6/" + filename + "_mean" + ext)
         #   writer.Execute(toW)

	
         #   self.dataManagerTest.writeResultsFromNumpyLabel(np.squeeze(labelmap),key)

