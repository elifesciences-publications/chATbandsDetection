# To Run the Network on Test Data:

## -Step 1: Running the Network to Detect the ON and OFF surfaces 
+ First, put all the images to be processed (STD Tiff stacks of chAT Bands) into the ImagesHere folder.

+ Then, open Matlab, make sure Matlab has included all the folders and subfolders inside of VNet, and run the script RunMe.m

+ After the Matlab script has finished running, the 2 chAT surfaces will be stored in SurfacesDectected Folder, plus a Tiff file containing the ON and OFF surfaces detected by the Network overlay on top of the Original Tiff file.

+ Manually verify that the overlays are correct by looking at the Tiff files mentioned above. If yes, import the 2 chAT surfaces, stored as filename_ON.mat and filename_OFF.mat into Sumbul RGC code to continue with the Warping step. These two .mat files contain the 2 surfaces that would have been returned by Sumbul's firSurfaceToSACAnnotation function.

######################################################################################################

## -Step 2: Clean Up
+ Make sure to delete or remove the images in ImageHere so that you can use the network again with other images.

+ Delete all the Detected Surfaces in DetectedSurfaces that are no longer needed also.

+ Delete all the Tiff files from ResultsON and ResultsOFF folder as well, if no longer needed,

########################################################################################################
Notes: In the case where the overlays are not correct, manually annotated the data, and store the Annotated files (xls or txt format) in the VNet/Dataset/Annotations folder so that the network can train itself with the new data.
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
+ Open a Terminal, locate the VNet Directory, and type: python main.py -trainON to run and train the network with the ON chATband data. This should take 2-3 days depending on the number of iterations specified in main.py (default is 100,000).

+ After the network has completed training the ON data, open a new Terminal, locate the VNet Directory, and type: python main.py -trainOFF to run and train the network with the OFF chATband data. This should also take 2-3 days depending on the number of iterations specified in main.py (default is 100,000).

+ The resulting Trained Models should be in Models/SnapshotsOFF for OFF data and Models/SnapshotsON for ON data.
 
######################################################################################################################
# VNet
Reference: https://sagarhukkire.github.io/Vnet-Cafffe_Guide/

 

 
 



 



 
 



 

