function thin_properties = detect_thin(glove_mask, img)

    % Fill inner holes to the glove mask
    se = strel('disk', 30); 
    glove_mask_closed = imclose(glove_mask, se);
    glove_mask_filled = imfill(glove_mask_closed, 'holes');
    
    % Convert the filled glove mask to binary
    binary_mask = glove_mask_filled > 0;
    
    % Apply the mask to the original input image
    glove_region = img;
    glove_region(repmat(~binary_mask, [1 1 size(img, 3)])) = 0;
    
    % Convert the RGB image of the glove region to the HSV color space
    glove_region_hsv = rgb2hsv(glove_region);
    
    % Reshape the image into a 2D array (rows = pixels, columns = HSV channels)
    pixels = reshape(glove_region_hsv, [], 3);
    
    % Filter out pixels that are close to black (V channel < 0.2)
    non_black_pixels = pixels(pixels(:, 3) > 0.2, :);
    
    % Check if there are non-black pixels remaining
    if isempty(non_black_pixels)
        disp('No non-black pixels found in the glove region.');
    else
        % Calculate the mean color of the non-black pixels
        mean_color_hsv = mean(non_black_pixels);
    
        % Convert the mean color back to RGB
        mean_color_rgb = hsv2rgb(mean_color_hsv);
    end

    % Extract the RGB components
    mean_color_r = mean_color_rgb(1);
    mean_color_g = mean_color_rgb(2);
    mean_color_b = mean_color_rgb(3);
    
    % Convert the floating-point RGB values to integers
    mean_color_r_int = round(mean_color_r * 255);
    mean_color_g_int = round(mean_color_g * 255);
    mean_color_b_int = round(mean_color_b * 255);
    
    % Print the integer RGB values
    fprintf('Mean Color (RGB): R = %d, G = %d, B = %d\n', mean_color_r_int, mean_color_g_int, mean_color_b_int);
    
    mean_color_pixel = [mean_color_r_int mean_color_g_int mean_color_b_int];
    
    % Define the deviation range for each RGB channel
    deviation_range = 0.2; % Adjust as needed
    
    % Calculate the minimum and maximum thresholds for each channel
    min_threshold = max(0, mean_color_pixel - deviation_range * 255);
    max_threshold = min(255, mean_color_pixel + deviation_range * 255);
    
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

    % Invert the binary mask to get thin areas
    thin_area_mask = ~binary_mask;
    
    % Create an image showing only the thin areas
    thin_area_image = bsxfun(@times, glove_region, uint8(thin_area_mask));
    
    % Convert thin_area_image to grayscale
    gray_thin_area_image = rgb2gray(thin_area_image);
    
    % Threshold the grayscale image to obtain a binary image
    binary_thin_area_image = imbinarize(gray_thin_area_image);
    
    % Use regionprops to calculate properties of connected components
    stats = regionprops(binary_thin_area_image, 'Area', 'BoundingBox');
    
    thin_properties = stats;

end
    

