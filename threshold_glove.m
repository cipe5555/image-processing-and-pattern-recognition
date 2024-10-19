function [thresholded_glove, main_glove_contour, glove_convex_hull] = threshold_glove(image)
    
    % Obtain the outer main glove contour
    [main_glove_contour] = detect_glove_contour(image);
    glove_mask = poly2mask(main_glove_contour(:,2), main_glove_contour(:,1), size(image, 1), size(image, 2));
    
    % Create a new image where everything outside the contour is remove
    masked_image = image;

    % Iterate over each color channel (RGB)
    for i = 1:3
        masked_image(:,:,i) = image(:,:,i) .* uint8(glove_mask);
    end
    
    % Convert the image to HSV color space
    hsvImage = rgb2hsv(masked_image);
    
    % Extract individual channels
    hueChannel = hsvImage(:,:,1);
    hue_in_contour = hueChannel(hueChannel > 0);
    
    saturationChannel = hsvImage(:,:,2);
    saturation_in_contour = saturationChannel(saturationChannel > 0);
    
    valueChannel = hsvImage(:,:,3);
    value_in_contour = valueChannel(valueChannel > 0);
    
    % Calculate statistics of each channel
    hueMean = mean2(hue_in_contour);
    hueStd = std2(hue_in_contour);
    
    saturationMean = mean2(saturation_in_contour);
    saturationStd = std2(saturation_in_contour);
    
    valueMean = mean2(value_in_contour);
    valueStd = std2(value_in_contour);
    
    % Define threshold ranges based on statistics
    threshold_multipler = 3.;
    hueThreshold = [hueMean - threshold_multipler*hueStd, hueMean + threshold_multipler*hueStd];
    saturationThreshold = [saturationMean - threshold_multipler*saturationStd, saturationMean + threshold_multipler*saturationStd];
    valueThreshold = [valueMean - threshold_multipler*valueStd, valueMean + threshold_multipler*valueStd];
    
    % Thresholding
    binaryMask = (hueChannel >= hueThreshold(1) & hueChannel <= hueThreshold(2)) & ...
                 (saturationChannel >= saturationThreshold(1) & saturationChannel <= saturationThreshold(2)) & ...
                 (valueChannel >= valueThreshold(1) & valueChannel <= valueThreshold(2));
    
    % Perform morphological operations
    thresholded_glove = imclose(binaryMask, strel('disk', 5));

    % Re-evaluate the main_glove_contour by extracting the largest contour
    glove_contours = bwboundaries(thresholded_glove);

    largest_contour_area = -1;
    largest_contour_index = -1;

    for i = 1:length(glove_contours)
        current_contour = glove_contours{i};
        current_contour_area = polyarea(current_contour(:, 2), current_contour(:, 1));
        if current_contour_area > largest_contour_area
            largest_contour_area = current_contour_area;
            largest_contour_index = i;
        end
    end

    main_glove_contour = glove_contours{largest_contour_index};

    % Calculate the convex hull of the main glove contour
    glove_convex_hull = convhull(main_glove_contour(:, 2), main_glove_contour(:, 1), 'Simplify', true);
end







