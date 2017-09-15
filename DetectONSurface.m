function [vzmesh] = DetectONSurface(im, name)
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
    
    %groundImage = zeros(nImage, mImage, NumberImages, 'uint8');
    
    %NBW = zeros(nImage,mImage,NumberImages,'uint16');
    %    TifLink = Tiff(FileTif, 'r');
    for i=1:c
        %        TifLink.setDirectory(i);
        %        im(:,:,i)=TifLink.read();
        BW(:,:,i)= imbinarize(im(:,:,i));
    end
    %    TifLink.close();
    
    ptONnum = 1;  %start w no points
    %ptOFFnum = 1; %no off also
    
    %%maybe pts
    pto = 0;
    %ptoff = 0;
    %cc = bwconncomp(BW,4);
    %L = labelmatrix(cc);
    groupONcount = 1;
    %cc = bwconncomp(BW,4);
    %L = labelmatrix(cc);
    %[r, c, h] = size(L);
    %for i = 1:h
    %rgb = label2rgb(L(:,:,i), 'jet', [.7 .7 .7], 'shuffle');
    %imshow(rgb)
    %end
    
    for i=1:NumberImages
        
        sliceONx  = zeros(10000,1);
        sliceONy = zeros(10000,1);
        sliceONz = zeros(10000,1);
        slicePtsON = 1;
        %
        
        GROUPON = zeros(500, 1);
        cc = bwconncomp(BW(:,:,i));
        L = labelmatrix(cc);
        [r, c] = size(L);
        %     %rgb [r, c, h] = size(L);= label2rgb(L, 'jet', [.7 .7 .7], 'noshuffle');
        %     %imshow(rgb)
        %
        %     %%%%%LOOP TOP TO BOTTOM OF COLUMN TO FIND ON
        PossibilityCol = zeros(c,1);
        colnum = 1;
        for colpix = 1:c
            %
            count = 0;
            oringroup = 0; %%first group, to mark whether next group is diff, as in diff line
            tempx = zeros(6,1); %init at every col
            tempy = zeros(6,1); %init at every col
            tempz = zeros(6,1);
            %tempsize = zeros(6,1);
            %%%flag to skip
            skipON = 0;
            %tic
            for rowpix = 1:r
                if L(rowpix,colpix) ~= 0
                    %oringroup = L(rowpix,colpix);  %%update the connected group we are in
                    %tempy(count) = colpix;
                    %tempx(count) = rowpix;
                    if L(rowpix, colpix) ~= oringroup  %%if find new group in that column
                        count = count + 1;
                        oringroup = L(rowpix,colpix);
                        tempy(count) = colpix;
                        tempx(count) = rowpix;
                        tempz(count) = i;
                        % tempsize(count) = size(find(L==L(rowpix,colpix)),1);
                    end
                end
            end
            
            if count == 1
                if slicePtsON == 1
                    sliceONx(slicePtsON) = tempx(1);
                    sliceONy(slicePtsON) = tempy(1);
                    sliceONz(slicePtsON) = tempz(1);
                    slicePtsON = slicePtsON + 1;
                    
                    if ~ismember(L(tempx(1),tempy(1)),GROUPON(:))
                        GROUPON(groupONcount) = L(tempx(1),tempy(1));
                        groupONcount = groupONcount + 1;
                    end
                    
                    ONX(ptONnum) = tempx(1);
                    ONY(ptONnum) = tempy(1);
                    ONZ(ptONnum) = tempz(1);
                    %groundImage(ONX(ptONnum),ONY(ptONnum),ONZ(ptONnum)) = 255 ;
                    ptONnum = ptONnum + 1;
                end
                if slicePtsON > 1
                    if abs(tempx(1) - sliceONx(slicePtsON - 1)) < 15
                        sliceONx(slicePtsON) = tempx(1);
                        sliceONy(slicePtsON) = tempy(1);
                        sliceONz(slicePtsON) = tempz(1);
                        slicePtsON = slicePtsON + 1;
                        
                        if ~ismember(L(tempx(1),tempy(1)),GROUPON(:))
                            GROUPON(groupONcount) = L(tempx(1),tempy(1));
                            groupONcount = groupONcount + 1;
                        end
                        
                        ONX(ptONnum) = tempx(1);
                        ONY(ptONnum) = tempy(1);
                        ONZ(ptONnum) = tempz(1);
                        %groundImage(ONX(ptONnum),ONY(ptONnum),ONZ(ptONnum)) = 255 ;
                        ptONnum = ptONnum + 1;
                    end
                end
            end
            if count == 2
                %[sortedX, sortedInds] = sort(tempsize(:),'descend');
                %onId = sortedInds(1);
                if ismember(L(tempx(1),tempy(1)),GROUPON(:))
                    sliceONx(slicePtsON) = tempx(1);
                    sliceONy(slicePtsON) = tempy(1);
                    sliceONz(slicePtsON) = tempz(1);
                    
                    slicePtsON = slicePtsON + 1;
                    
                    ONX(ptONnum) = tempx(1);
                    ONY(ptONnum) = tempy(1);
                    ONZ(ptONnum) = tempz(1);
                    
                    ptONnum = ptONnum + 1;
                end
                if ismember(L(tempx(2),tempy(2)),GROUPON(:))
                    sliceONx(slicePtsON) = tempx(2);
                    sliceONy(slicePtsON) = tempy(2);
                    sliceONz(slicePtsON) = tempz(2);
                    
                    slicePtsON = slicePtsON + 1;
                    
                    ONX(ptONnum) = tempx(2);
                    ONY(ptONnum) = tempy(2);
                    ONZ(ptONnum) = tempz(2);
                    
                    ptONnum = ptONnum + 1;
                end
            end
            if count > 2
                PossibilityCol(colnum) = colpix;
                colnum = colnum + 1;
            end
        end
        %%%loop again%%%%%%%%%%%%%%%
        for colpix = 1:c
            if ~ismember(colpix,PossibilityCol(:))
                break
            else
                count = 0;
                oringroup = 0; %%first group, to mark whether next group is diff, as in diff line
                tempx = zeros(6,1); %init at every col
                tempy = zeros(6,1); %init at every col
                tempz = zeros(6,1);
                tempsize = zeros(6,1);
                %%%flag to skip
                skipON = 0;
                %tic
                for rowpix = 1:r
                    if ismember(L(rowpix,colpix),GROUPON(:))
                        % sliceONx(slicePtsON) = rowpix;
                        % sliceONy(slicePtsON) = colpix;
                        % sliceONz(slicePtsON) = i;
                        % slicePtsON = slicePtsON + 1;
                        ONX(ptONnum) = rowpix;
                        ONY(ptONnum) = colpix;
                        ONZ(ptONnum) = i;
                        ptONnum = ptONnum + 1;
                        break
                    end
                end
            end
        end
    end
    ONX = ONX(ONX~=0);
    ONY = ONY(ONY~=0);
    ONZ = ONZ(ONZ~=0);
    %
    z = ONX;
    y = ONY;
    x = ONZ;
    %
    xMax = max(x); yMax = max(y);
    [zgrid,xgrid,ygrid] = gridfit(x,y,z,[[1:3:xMax-1] xMax],[[1:3:yMax-1] yMax],'smoothness',1);
    % linearly (fast) interpolate to fine grid
    [xi,yi]=meshgrid(1:xMax,1:yMax); xi = xi'; yi = yi';
    vzmesh=interp2(xgrid,ygrid,zgrid,xi,yi,'*spline',mean(zgrid(:)));
   % vz = uint16(vzmesh);
    
    
    %mesh(vzmesh);hold on;mesh(vzmesh2);
    
    
    %%%create groundtruth to test
    %'/home/quan/Desktop/VNet/ImagesHere/*chAT_STD.tif'
%     orgname = strrep(FileTif,'_rotate.tif','');
%     orgname = strcat(orgname,'.tif');
%     orgname = strcat('/media/areca_raid/VNet/ImagesHere/',orgname);
%     
%     [a,b,c] = size(BW);
%     groundImage = zeros(c,b,a);
%     validationImage = zeros(c,b,a,'uint16');
%     tem=zeros(c,b,3);
%     TifLink = Tiff(orgname, 'r');
%     for i=1:a
%         TifLink.setDirectory(i);
%         validationImage(:,:,i)=TifLink.read();
%     end
%     TifLink.close();
%     % InfoImage=imfinfo(FileTif);
%     % mImage=InfoImage(1).Width;
%     % nImage=InfoImage(1).Height;
%     % NumberImages=length(InfoImage);
%     % im=zeros(nImage,mImage,NumberImages,'uint8');
%     [r c] = size(vz);
%     for i = 1:r
%         for j = 1:c
%             if vz(i,j) == 0
%                 vz(i,j) = 1;
%             end
%             groundImage(i,j, vz(i,j)) = 255;
%             %validationImage(i,j,vz(i,j)) = 0;
%         end
%     end
%     
%     
%     %  [r c] = size(vz2);
%     %  for i = 1:r
%     %      for j = 1:c
%     %          if vz2(i,j) == 0
%     %              vz2(i,j) = 1;
%     %          end
%     %          groundImage(j,i,vz2(i,j)) = 255;
%     %          validationImage(j,i,vz2(i,j)) = 0;
%     %      end
%     %  end
%     
%     
%     %%%store mask to verify correctness%%%%%
%     %   maskName = strrep(FileTif,'_rotate.tif','_validation_Mask.tif');
%     %   maskName = strcat('/home/quan/Desktop/VNet/Validation/',maskName);
%     %   imwrite(groundImage(:,:,1), maskName);
%     %   for k = 2:size(groundImage,3)
%     %       imwrite(groundImage(:,:,k), maskName, 'writemode', 'append');
%     %   end
%     
%     
%     %%store overlay%%%
%     resultName = strrep(FileTif,'_rotate.tif','_validation_ON.tif');
%     resultName = strcat('/media/areca_raid/VNet/SurfacesDetected/',resultName);
%     % resultName = strcat('/media/areca_raid/Quan/SurfacesDetected/',resultName);
%     %imwrite(validationImage(:,:,1), resultName);
%     %for k = 2:size(validationImage,3)
%     %    imwrite(validationImage(:,:,k), resultName, 'writemode', 'append');
%     %end
%     
%     for i = 1:size(validationImage,3)
%         
%         %----- Add Raw as Grey -----%
%         tem(:,:,1) = validationImage(:,:,i) ./ 10;
%         tem(:,:,2) = validationImage(:,:,i) ./ 10;
%         tem(:,:,3) = validationImage(:,:,i) ./ 10;
%         
%         %----- Add CNN as Yellow -----%
%         tem(:,:,1) = tem(:,:,2) + groundImage(:,:,i);
%         tem(:,:,2) = tem(:,:,3) + groundImage(:,:,i);
%         
%         %----- Normalize -----%
%         tem = tem ./ max(tem(:));
%         
%         %----- Save -----%
%         if i == 1
%             imwrite(tem, resultName);
%         else
%             imwrite(tem, resultName, 'writemode', 'append');
%         end
%     end
%     
%     %%store surfaces%%%
%     ONmat = strrep(FileTif,'_rotate.tif','_ON.mat');
%     ONmat = strcat('/media/areca_raid/VNet/SurfacesDetected/',ONmat);
%     %OFFmat = strrep(FileTif,'_rotate.tif','_OFF.mat');
%     %OFFmat = strcat('/home/quan/Desktop/VNet/SurfacesDetected/',OFFmat);
%     save(ONmat, 'vzmesh');
%     
%     % save(OFFmat, 'vzmesh2');
%     clear im
%     clear tem
%     clear groundImage
%     clear validationImage
%     clear BW
    clear ONX
    clear ONY
    clear ONZ
    clear x
    clear y
    clear z
end

end
