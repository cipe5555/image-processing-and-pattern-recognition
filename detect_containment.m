function containment_properties = detect_containment(glove_mask, img)

    % Fill inner holes to the glove mask
    se = strel('disk', 5); 
    glove_mask_closed = imclose(glove_mask, se);
    glove_mask_filled = imfill(glove_mask_closed, 'holes');
    
    % Convert the filled glove mask to binary
    binary_mask = glove_mask_filled > 0;
    
    % Apply the mask to the original input image
    glove_region = img;
    glove_region(repmat(~binary_mask, [1 1 size(img, 3)])) = 0;
    
    % Define the mean RGB for containment
    containment_rgb = [54 119 93];
    
    % Define the deviation range for each RGB channel
    deviation_range = 0.1;
    
    % Calculate the minimum and maximum thresholds for each channel
    min_threshold = max(0, containment_rgb - deviation_range * 255);
    max_threshold = min(255, containment_rgb + deviation_range * 255);
    
    % Clip the threshold values to ensure they are within the valid RGB range
    min_threshold = min(max_threshold, min_threshold); % Clip min_threshold
    max_threshold = max(min_threshold, max_threshold); % Clip max_threshold
    
    % Print the minimum and maximum thresholds for each channel
    fprintf('Minimum Threshold (RGB): R = %d, G = %d, B = %d\n', min_threshold);
    fprintf('Maximum Threshold (RGB): R = %d, G = %d, B = %d\n', max_threshold);
    
    % Initialize binary mask
    binary_mask = true(size(glove_region, 1), size(glove_region, 2));
    
    % Loop through each pixel
    for i = 1:size(glove_region, 1)
        for j = 1:size(glove_region, 2)
            % Get RGB values of the current pixel
            pixel_rgb = squeeze(glove_region(i, j, :))';
            
            % Check if the pixel lies within the threshold range for each channel
            is_within_threshold = all(pixel_rgb >= min_threshold & pixel_rgb <= max_threshold);
            
            % Update the binary mask based on the comparison result
            binary_mask(i, j) = is_within_threshold;
        end
    end
    
    % Extract the pixels from the glove region based on the binary mask
    extracted_region = bsxfun(@times, glove_region, uint8(binary_mask));
    
    % Convert containment_area_image to grayscale
    gray_containment_area_image = rgb2gray(extracted_region);
    
    % Threshold the grayscale image to obtain a binary image
    binary_containment_area_image = imbinarize(gray_containment_area_image);
    
    % Use regionprops to calculate properties of connected components
    stats = regionprops(binary_containment_area_image, 'Area', 'BoundingBox');

    containment_properties = stats;

end