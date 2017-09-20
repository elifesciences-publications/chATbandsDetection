function [vzmesh] = DetectONSurface2(im, name)
%STEP 5%%%%%%%%%%%%%%%%SURFACE OFF DETECTION%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%files = dir('/home/quan/Desktop/VNet/Results/*_rotate.tif');
%for file = files'
FileTif = name;
existfile = strrep(FileTif,'_rotate.tif','_validation_ON_OFF_2.tif');
if exist(strcat('/media/areca_raid/VNet/SurfacesDetected/',existfile), 'file') ~= 2
    %FileTif = '/home/quan/Desktop/VNet/Results/00643_1L_C05_chAT_STD_rotate.tif';
    %FileTif = '00505_2R_C01_chAT_STD.tif'
    %InfoImage=imfinfo(FileTif);
    %mImage=InfoImage(1).Width;
    %nImage=InfoImage(1).Height;
    %NumberImages=length(InfoImage);
    [a,b,c] = size(im);
    NumberImages = c;
    BW=zeros(a,b,c,'uint8');
    
    for i=1:c
        %        TifLink.setDirectory(i);
        %        im(:,:,i)=TifLink.read();
        BW(:,:,i)= imbinarize(im(:,:,i),0.01);
    end

    CC = bwconncomp(BW);
    numOfPixels = cellfun(@numel,CC.PixelIdxList);
    [unused, indexOfMax] = max(numOfPixels);
    numOfPixels(indexOfMax) = [];
    [unused2, indexOfSecondMax] = max(numOfPixels);
    biggest = zeros(size(BW));
    biggest(CC.PixelIdxList{indexOfMax}) = 1;
    %biggest(CC.PixelIdxList{indexOfSecondMax}) = 1;
   [r,c,h] = size(biggest);
   ptONnum = 1;
   for i=1:NumberImages
       %imshow(biggest(:,:,i))
       for cpix = 1:5:c
           cnt = 1;
           tempRow = zeros(1,50);
           for rpix = 1:r
                if biggest(rpix, cpix, i) == 1
                   tempRow(cnt) = rpix;
                   cnt = cnt + 1;
                end
           end
           tempRow = tempRow(tempRow~=0);
           if size(tempRow,2) > 1
               randrow = tempRow(round(size(tempRow,2)/2));
               ONX(ptONnum) = randrow;
               ONY(ptONnum) = cpix;
               ONZ(ptONnum) = i;
               ptONnum = ptONnum + 1;
           end
           %tempRow = [];
       end
   end

  %  ONX = ONX(ONX~=0);
  %  ONY = ONY(ONY~=0);
  %  ONZ = ONZ(ONZ~=0);
    %
    z = ONX;
    y = ONY;
    x = ONZ;
    %
    xMax = max(x); yMax = max(y);
    [zgrid,xgrid,ygrid] = gridfit(x,y,z,[[1:3:xMax-1] xMax],[[1:3:yMax-1] yMax],'smoothness',1);
    % linearly (fast) interpolate to fine grid
    [xi,yi]=meshgrid(1:xMax,1:yMax); xi = xi'; yi = yi';
    vzmesh=interp2(xgrid,ygrid,zgrid,xi,yi,'*linear',mean(zgrid(:)));
   % vz = uint16(vzmesh);
    
    
  

    clear ONX
    clear ONY
    clear ONZ
    clear x
    clear y
    clear z
end

end
