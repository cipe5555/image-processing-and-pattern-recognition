function [glove_contour] = detect_glove_contour(image)

    glove_hsv = rgb2hsv(image);

    % Extract individual channels
    hue_channel = glove_hsv(:,:,1);
    saturation_channel = glove_hsv(:,:,2);
    value_channel = glove_hsv(:,:,3);

    % Calculate histograms for each channel
    numBins = 256;
    hueHistogram = imhist(hue_channel, numBins);
    saturationHistogram = imhist(saturation_channel, numBins);
    valueHistogram = imhist(value_channel, numBins);

    % Find the bin with the highest count for each channel
    [~, dominantHueBin] = max(hueHistogram);
    [~, dominantSaturationBin] = max(saturationHistogram);
    [~, dominantValueBin] = max(valueHistogram);

    % Convert the dominant bins to actual values
    dominant_hue = (dominantHueBin - 1) / numBins;
    dominant_saturation = (dominantSaturationBin - 1) / numBins;
    dominant_value = (dominantValueBin - 1) / numBins;

    % Extract the dominant color
    dominant_color = [dominant_hue, dominant_saturation, dominant_value];

    % Define light and dark background threshold
    bright_bg_lower = [0,0,128] / 255;
    bright_bg_upper = [255,255,255] / 255;

    dark_bg_lower = [0,0,0] / 255;
    dark_bg_upper = [255,255,127] / 255;

    % Check if dominant color is within the dark background range
    is_dark = all(dominant_color >= dark_bg_lower) && all(dominant_color <= dark_bg_upper);

    % Check if dominant color is within the light background range
    is_bright = all(dominant_color >= bright_bg_lower) && all(dominant_color <= bright_bg_upper);

    % Define lower and upper bounds for glove color in HSV space
    if is_bright
        glove_lower = [0,0,85] / 255;
        glove_upper = [255,110,255] / 255;
    end
    if is_dark
        glove_lower = [0,0,0] / 255;
        glove_upper = [255,255,110] / 255;
    end

    % Create mask for the glove
    glove_mask = (glove_hsv(:,:,1) >= glove_lower(1) & glove_hsv(:,:,1) <= glove_upper(1)) & ...
           (glove_hsv(:,:,2) >= glove_lower(2) & glove_hsv(:,:,2) <= glove_upper(2)) & ...
           (glove_hsv(:,:,3) >= glove_lower(3) & glove_hsv(:,:,3) <= glove_upper(3));

    % Extract glove region
    glove_extracted = glove_hsv;
    glove_extracted(repmat(~glove_mask,[1 1 3])) = 0;

    % Convert to binary mask
    glove_binary = glove_extracted(:,:,1) > 0 | glove_extracted(:,:,2) > 0 | glove_extracted(:,:,3) > 0;
    glove_binary = imcomplement(glove_binary);

    % Perform morphological operations
    se = strel('square', 9);
    glove_binary = imdilate(glove_binary, se);
    glove_binary = imerode(glove_binary, se);
    glove_binary = imfill(glove_binary, 'holes');

    % Find the main glove contour by extracting the largest contour
    glove_contours = bwboundaries(glove_binary);

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

    glove_contour = glove_contours{largest_contour_index};
end




