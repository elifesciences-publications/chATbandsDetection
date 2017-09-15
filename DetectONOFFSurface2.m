function [] = DetectONOFFSurface2(imON,imOFF, name)
%STEP 5%%%%%%%%%%%%%%%%SURFACE OFF DETECTION%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%files = dir('/home/quan/Desktop/VNet/Results/*_rotate.tif');
%for file = files'
vzmesh = DetectONSurface(imON,name);
vzmesh2 = DetectOFFSurface(imOFF,name);

vz = uint16(vzmesh);
vz2 = uint16(vzmesh2);

%%%create groundtruth to test
%'/home/quan/Desktop/VNet/ImagesHere/*chAT_STD.tif'
orgname = strrep(name,'_rotate.tif','');
orgname = strcat(orgname,'.tif');
orgname = strcat('/media/areca_raid/VNet/ImagesHere/',orgname);

[a,b,c] = size(imON);
groundImage = zeros(c,b,a);
validationImage = zeros(c,b,a,'uint16');
tem=zeros(c,b,3);
TifLink = Tiff(orgname, 'r');
for i=1:a
    TifLink.setDirectory(i);
    validationImage(:,:,i)=TifLink.read();
end
TifLink.close();
% InfoImage=imfinfo(FileTif);
% mImage=InfoImage(1).Width;
% nImage=InfoImage(1).Height;
% NumberImages=length(InfoImage);
% im=zeros(nImage,mImage,NumberImages,'uint8');
[r c] = size(vz);
for i = 1:r
    for j = 1:c
        if vz(i,j) == 0
            vz(i,j) = 1;
        end
        groundImage(i,j, vz(i,j)) = 255;
        %validationImage(i,j,vz(i,j)) = 0;
    end
end


[r c] = size(vz2);
for i = 1:r
    for j = 1:c
        if vz2(i,j) == 0
            vz2(i,j) = 1;
        end
        groundImage(i,j,vz2(i,j)) = 255;
        %          validationImage(j,i,vz2(i,j)) = 0;
    end
end


%%%store mask to verify correctness%%%%%
%   maskName = strrep(FileTif,'_rotate.tif','_validation_Mask.tif');
%   maskName = strcat('/home/quan/Desktop/VNet/Validation/',maskName);
%   imwrite(groundImage(:,:,1), maskName);
%   for k = 2:size(groundImage,3)
%       imwrite(groundImage(:,:,k), maskName, 'writemode', 'append');
%   end

   ONmat = strrep(name,'_rotate.tif','_ON_2.mat');
   ONmat = strcat('/media/areca_raid/VNet/SurfacesDetected/',ONmat);
   OFFmat = strrep(name,'_rotate.tif','_OFF_2.mat');
   OFFmat = strcat('/media/areca_raid/VNet/SurfacesDetected/',OFFmat);
   save(ONmat, 'vzmesh');
   save(OFFmat,'vzmesh2');
%%store overlay%%%
resultName = strrep(name,'_rotate.tif','_validation_ON_OFF_2.tif');
resultName = strcat('/media/areca_raid/VNet/SurfacesDetected/',resultName);
% resultName = strcat('/media/areca_raid/Quan/SurfacesDetected/',resultName);
%imwrite(validationImage(:,:,1), resultName);
%for k = 2:size(validationImage,3)
%    imwrite(validationImage(:,:,k), resultName, 'writemode', 'append');
%end

for i = 1:size(validationImage,3)
    
    %----- Add Raw as Grey -----%
    tem(:,:,1) = validationImage(:,:,i) ./ 10;
    tem(:,:,2) = validationImage(:,:,i) ./ 10;
    tem(:,:,3) = validationImage(:,:,i) ./ 10;
    
    %----- Add CNN as Yellow -----%
    tem(:,:,2) = tem(:,:,3) + groundImage(:,:,i);
    tem(:,:,3) = tem(:,:,2) + groundImage(:,:,i);
    
    %----- Normalize -----%
    tem = tem ./ max(tem(:));
    
    %----- Save -----%
    if i == 1
        imwrite(tem, resultName);
    else
        imwrite(tem, resultName, 'writemode', 'append');
    end
end

end