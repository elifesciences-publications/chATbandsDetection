function [] = DetectONOFFSurface2(imON,imOFF, name)
%STEP 5%%%%%%%%%%%%%%%%SURFACE OFF DETECTION%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%files = dir('/home/quan/Desktop/VNet/Results/*_rotate.tif');
%for file = files'
vzmesh = DetectONSurface2(imON,name);
vzmesh2 = DetectOFFSurface2(imOFF,name);
[a b] = size(vzmesh);
[c d] = size(vzmesh2);
if a > c
    a = c;
end
if b > d
    b = d;
end
for i = 1:a
    for j = 1:b
        if uint16(vzmesh(i,j)) == uint16(vzmesh2(i,j))
            vzmesh2(i,j) = vzmesh2(i,j) + 1;
        end
    end
end

diff = vzmesh2(1:a,1:b) - vzmesh(1:a,1:b);
B = diff < 0;
  
for i = 1:a
    for j = 1:b
        if B(i,j) == 1 %% if on is not on top of off?
            temp = vzmesh2(i,j);
            vzmesh2(i,j) = vzmesh(i,j);
            vzmesh(i,j) = temp;
        end

    end
end
%diff = vzmesh - vzmesh2;
%outlier = find(diff < 0);


vz = uint16(vzmesh);
vz2 = uint16(vzmesh2);

%diff2 = vz - vz2;

%%%create groundtruth to test
%'/home/quan/Desktop/VNet/ImagesHere/*chAT_STD.tif'
orgname = strrep(name,'_rotate.tif','');
orgname = strcat(orgname,'.tif');
orgname = strcat('/media/areca_raid/VNet/ImagesHere/',orgname);

[a,b,c] = size(imON);
groundImage = zeros(c,b,a); %%on
groundImage2 = zeros(c,b,a); %%off 
validationImage = zeros(c,b,a,'uint16');
tem=zeros(c,b,3);
%tem2=zeros(c,b,3);
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
      
        %groundImage(i,j, vz(i,j)) = 255;
        groundImage(i,j,vz(i,j)) = 255;
        
        %validationImage(i,j,vz(i,j)) = 0;
    end
end


[r c] = size(vz2);
for i = 1:r
    for j = 1:c
        if vz2(i,j) == 0
            vz2(i,j) = 1;
        end
        groundImage2(i,j,vz2(i,j)) = 255;
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
    
    tem(:,:,1) = tem(:,:,2) + groundImage2(:,:,i);
    tem(:,:,2) = tem(:,:,3) + groundImage2(:,:,i);
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
