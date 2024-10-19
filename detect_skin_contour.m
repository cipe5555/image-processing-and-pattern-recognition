function [skin_mask, finger_stats] = detect_skin_contour(image)

    hsv_image = rgb2hsv(image);

    % Define skin color range
    hueRange = [0.01, 0.1];
    saturationRange = [0.1, 0.7];
    valueRange = [0.35, 1];
    
    % Create mask based on the defined thresholds
    skin_mask = (hsv_image(:,:,1) >= hueRange(1)) & (hsv_image(:,:,1) <= hueRange(2)) & ...
                (hsv_image(:,:,2) >= saturationRange(1)) & (hsv_image(:,:,2) <= saturationRange(2)) & ...
                (hsv_image(:,:,3) >= valueRange(1)) & (hsv_image(:,:,3) <= valueRange(2));

    % Perform morphological operations
    se = strel('disk', 5);
    skin_mask = imerode(skin_mask, se);
    skin_mask = imdilate(skin_mask, se);
    skin_mask = imfill(skin_mask, 'holes');

    % Extract connected components
    labeledImage = bwlabel(skin_mask);
    finger_stats = regionprops(labeledImage, 'Area', 'BoundingBox');  
end


