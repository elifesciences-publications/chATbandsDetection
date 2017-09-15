# To Run the Network on Test Data: 

## -Step 1: Running the Network to Detect the ON and OFF surfaces 
+ First, put all the images to be processed (STD Tiff stacks of chAT Bands) into the ImagesHere folder.

+ Then, open Matlab, make sure Matlab has included all the folders and subfolders inside of VNet, and run the script RunMe.m

+ After the Matlab script has finished running, the 2 chAT surfaces will be stored in SurfacesDectected Folder, plus a Tiff file for each raw image containing the ON and OFF surfaces detected by the Network overlayed on top of the Original Tiff file. To improve correctness, for each raw images, there will be 2 results: filename_validation_ON_OFF.tif and filename_validation_ON_OFF_2.tif, returned by 2 different post-processing algorithms. Hence, for each raw image, there will be 2 Tiff files and 4 Surfaces Detected: filename_ON.mat, filename_ON_2.mat, filename_OFF.mat and filename_OFF_2.mat. 

+ It's up to the user to decide which combination works best, and which resulting surfaces should be used. Hence, using ImageJ, manually verify that the overlays are correct by looking at the Tiff files mentioned above, and pick the best results. Once finished choosing, import the 2 chAT surfaces that looks best, stored as filename_ON.mat and filename_OFF.mat into Sumbul RGC code to continue with the Warping step. These two .mat files contain the 2 surfaces that would have been returned by Sumbul's firSurfaceToSACAnnotation function.

######################################################################################################

## -Step 2: Clean Up
+ Make sure to delete or remove the images in ImageHere so that you can use the network again with other images.

+ Delete all the .mat files and .tif files in DetectedSurfaces that are no longer needed.

+ Delete all the Tiff files from ResultsON and ResultsOFF folder as well, since those are just there to verify the raw network prediction.

########################################################################################################
### Notes: 
+ In the case where the overlays are not correct, manually annotated the data, and store the Annotated files (xls or txt format) in the VNet/Dataset/Annotations folder so that the network can train itself with the new data.

+ Make sure the SnapshotON and SnapshotOFF parameters in VNet/main.py have not been modified by anyone else before running Runme.m
Those parameters should be modified if the network is to be trained again, as will be discussed below, but basically, don't make any change to anything in main.py if you don't know what you are doing! Just put images in Imagehere and run RunMe.m

### Common Errors:
+ If when running the network, the error Out of Memory occurred, open a terminal, run nvidia-smi to check the status of the GPU and what process is taking up the GPU memory. Simply kill that process using the Linux terminal with the kill or killall command.  
########################################################################################################

# To Train the Network with new Data:

## -Step 1: Install Dependencies and Libraries 
+ Run CaffeInstallation.sh and PythonLibraryInstallation.sh. To run the 2 files, either double-click on the file name and choose 'Run On Terminal', or manually open up a new Terminal, change directory (cd command) to locate the file, and type:
            ./filename.sh 
in order to execute the command that download and install dependencies necessary to run pycaffe.

## -Step 2: Prepare training data
+ The ON and OFF band should be trained on separated network for best result, and all the images has to be resized to 128x128x64 before feeding into the network. The steps on how to do so is below.

+ First, put all the raw images that needed to be train in the Dataset/RawImages folder.

+ Then, put the corresponding ON and OFF .txt annotation files into the Dataset/Annotations Folder. Note that the annotation files should be in .txt format.

+ Find the CreateTrainingData.m script and run it on Matlab to create the Groundtruths, resize the images and the groundtruths, and put them in the right location ready to be trained.

## -Step 3: Run the training script
+ Locate the VNet Directory, find main.py file and change the SnapshotON and SnapshotOFF parameters to 0 to retrain from scratch, or to a desired iteration values (multiple of 500). The network will look at those parameters, and choose what iteration to resume training if a model already exists, or just start over from scratch. The default iteration is not 0, since SnapshotON and SnapshotOFF also tell the network what model it should use at what iteration when we feed in Test Data. If the default Snapshot Iteration is ever changed for retraining purpose, make sure to change it back to what it should be (Something like 100,000 or 99,000) for Testing purpose.

+ Open a Terminal, locate the VNet Directory, and type: python main.py -trainON to run and train the network with the ON chATband data. This should take 2-3 days depending on the number of iterations specified in main.py (default is 100,000).

+ After the network has completed training the ON data, open a new Terminal, locate the VNet Directory, and type: python main.py -trainOFF to run and train the network with the OFF chATband data. This should also take 2-3 days depending on the number of iterations specified in main.py (default is 100,000).

+ The resulting Trained Models should be in Models/SnapshotsOFF for OFF data and Models/SnapshotsON for ON data.
 
######################################################################################################################
# VNet
Reference: https://sagarhukkire.github.io/Vnet-Cafffe_Guide/

 

 
 



 



 
 



 

