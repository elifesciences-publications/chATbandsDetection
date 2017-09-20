clear all;
close all;
files = dir('/media/areca_raid/VNet/Dataset/Annotations/*_OFF.txt');
for file = files'
    %fprintf(file.name)
    % Do some stuff
    fname = file.name;
    table = readtable(fname, 'Delimiter','\t');
    fname = strrep(fname,'_OFF.txt','');
    maskname = strcat(fname, '_chAT_segmentation.tif')
    imagename = strcat(fname, '_chAT_STD.tif');
    trainimagename = strcat(fname, '_chAT.tif');
    %fname2 = strcat(fname,'_ON.txt'); %name of the On image
    if exist(strcat('/media/areca_raid/VNet/Dataset/Train/OFF/',maskname), 'file') ~= 2
    %%%get info of the image, basically w, h, d 
    InfoImage=imfinfo(strcat('/media/areca_raid/VNet/Dataset/RawImages/',imagename));
    mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height;
    NumberImages=length(InfoImage); %depth
    im=zeros(nImage,mImage,NumberImages,'uint16')
    %%%read in the original image
    TifLink = Tiff(strcat('/media/areca_raid/VNet/Dataset/RawImages/',imagename), 'r');
    for i=1:NumberImages
        TifLink.setDirectory(i);
        im(:,:,i)=TifLink.read();
    end
    TifLink.close();

    
    
    %create a black mask
    groundImage = zeros(mImage, nImage, NumberImages);


    x = table.X;
    z = table.Y; %cause it's actually x and z in the image
    y = table.Slice; %this should be y
    % add 1 to x and z, butnot to y because FIJI point tool starts from 0 for pixels of an image
    % but from 1 for slice of a stack
    x=x+1; z=z+1;
    % find the maximum boundaries
    xMax = max(x); yMax = max(y);
    % smoothened fit (with extrapolation) to a grid - to save time, make the grid coarser (every 3 pixels)
    [zgrid,xgrid,ygrid] = gridfit(x,y,z,[[1:3:xMax-1] xMax],[[1:3:yMax-1] yMax],'smoothness',1);
    % linearly (fast) interpolate to fine grid
    [xi,yi]=meshgrid(1:xMax,1:yMax); xi = xi'; yi = yi';
    vzmesh=interp2(xgrid,ygrid,zgrid,xi,yi,'*spline',mean(zgrid(:)));
    vz = uint16(vzmesh); 

    [r c] = size(vz);
    for i = 1:r
        for j = 1:c
            if vz(i,j) == 0
                vz(i,j) = 1;
            end
            groundImage(j,i,vz(i,j)) = 1;
        end
    end
    ny=128;nx=128;nz=64; %% desired output dimensions
    [y x z]=ndgrid(linspace(1,size(groundImage,1),ny),...
          linspace(1,size(groundImage,2),nx),...
          linspace(1,size(groundImage,3),nz));
    imOut=interp3(double(groundImage),x,y,z);
    imOut = uint16(imOut);
    
    %%%%%%%%%%%%%%%%Write the
    %%%%%%%%%%%%%%%%Mask%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    imwrite(imOut(:,:,1), strcat('/media/areca_raid/VNet/Dataset/Train/OFF/',maskname));
    for k = 2:size(imOut,3)
        imwrite(imOut(:,:,k), strcat('/media/areca_raid/VNet/Dataset/Train/OFF/',maskname), 'writemode', 'append');
    end
    
    %%%%%%%resize orginal images%%%%%%%%%%%%%%%%%%%%%%%%%
    ny=128;nx=128;nz=64; %% desired output dimensions
    [y x z]=...
        ndgrid(linspace(1,size(im,1),ny),...
        linspace(1,size(im,2),nx),...
        linspace(1,size(im,3),nz));
    imOut2=interp3(double(im),x,y,z);
    imOut2 = uint16(imOut2);
    %%%%%%%%%%%%    write the image
    imwrite(imOut2(:,:,1), strcat('/media/areca_raid/VNet/Dataset/Train/OFF/',trainimagename));
    for k = 2:size(imOut2,3)
        imwrite(imOut2(:,:,k), strcat('/media/areca_raid/VNet/Dataset/Train/OFF/',trainimagename), 'writemode', 'append');
    end
    
    end
end

clear files;
files = dir('/media/areca_raid/VNet/Dataset/Annotations/*_ON.txt');
for file = files'
    %fprintf(file.name)
    % Do some stuff
    fname = file.name;
    table = readtable(fname, 'Delimiter','\t');
    fname = strrep(fname,'_ON.txt','');
    maskname = strcat(fname, '_chAT_segmentation.tif')
    imagename = strcat(fname, '_chAT_STD.tif');
    trainimagename = strcat(fname, '_chAT.tif');
    %fname2 = strcat(fname,'_ON.txt'); %name of the On image
    if exist(strcat('/media/areca_raid/VNet/Dataset/Train/ON/',maskname), 'file') ~= 2
    %%%get info of the image, basically w, h, d 
    InfoImage=imfinfo(strcat('/media/areca_raid/VNet/Dataset/RawImages/',imagename));
    mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height;
    NumberImages=length(InfoImage); %depth
    im=zeros(nImage,mImage,NumberImages,'uint16')
    %%%read in the original image
    TifLink = Tiff(strcat('/media/areca_raid/VNet/Dataset/RawImages/',imagename), 'r');
    for i=1:NumberImages
        TifLink.setDirectory(i);
        im(:,:,i)=TifLink.read();
    end
    TifLink.close();

    
    
    %create a black mask
    groundImage = zeros(mImage, nImage, NumberImages);


    x = table.X;
    z = table.Y; %cause it's actually x and z in the image
    y = table.Slice; %this should be y
    % add 1 to x and z, butnot to y because FIJI point tool starts from 0 for pixels of an image
    % but from 1 for slice of a stack
    x=x+1; z=z+1;
    % find the maximum boundaries
    xMax = max(x); yMax = max(y);
    % smoothened fit (with extrapolation) to a grid - to save time, make the grid coarser (every 3 pixels)
    [zgrid,xgrid,ygrid] = gridfit(x,y,z,[[1:3:xMax-1] xMax],[[1:3:yMax-1] yMax],'smoothness',1);
    % linearly (fast) interpolate to fine grid
    [xi,yi]=meshgrid(1:xMax,1:yMax); xi = xi'; yi = yi';
    vzmesh=interp2(xgrid,ygrid,zgrid,xi,yi,'*spline',mean(zgrid(:)));
    vz = uint16(vzmesh); 

    [r c] = size(vz);
    for i = 1:r
        for j = 1:c
            if vz(i,j) == 0
                vz(i,j) = 1;
            end
            groundImage(j,i,vz(i,j)) = 1;
        end
    end
    ny=128;nx=128;nz=64; %% desired output dimensions
    [y x z]=ndgrid(linspace(1,size(groundImage,1),ny),...
          linspace(1,size(groundImage,2),nx),...
          linspace(1,size(groundImage,3),nz));
    imOut=interp3(double(groundImage),x,y,z);
    imOut = uint16(imOut);
    
    %%%%%%%%%%%%%%%%Write the
    %%%%%%%%%%%%%%%%Mask%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    imwrite(imOut(:,:,1), strcat('/media/areca_raid/VNet/Dataset/Train/ON/',maskname));
    for k = 2:size(imOut,3)
        imwrite(imOut(:,:,k), strcat('/media/areca_raid/VNet/Dataset/Train/ON/',maskname), 'writemode', 'append');
    end
    
    %%%%%%%resize orginal images%%%%%%%%%%%%%%%%%%%%%%%%%
    ny=128;nx=128;nz=64; %% desired output dimensions
    [y x z]=...
        ndgrid(linspace(1,size(im,1),ny),...
        linspace(1,size(im,2),nx),...
        linspace(1,size(im,3),nz));
    imOut2=interp3(double(im),x,y,z);
    imOut2 = uint16(imOut2);
    %%%%%%%%%%%%    write the image
    imwrite(imOut2(:,:,1), strcat('/media/areca_raid/VNet/Dataset/Train/ON/',trainimagename));
    for k = 2:size(imOut2,3)
        imwrite(imOut2(:,:,k), strcat('/media/areca_raid/VNet/Dataset/Train/ON/',trainimagename), 'writemode', 'append');
    end
    
    end
end
