function stain_or_dirt = detect_stain_and_dirt(image, boundary)

    glove_hsv = rgb2hsv(image);

    % Extract each channel
    hue_channel = glove_hsv(boundary(:,1),boundary(:,2),1);
    saturation_channel = glove_hsv(boundary(:,1),boundary(:,2),2);
    value_channel = glove_hsv(boundary(:,1),boundary(:,2),3);

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

    % Define stain threshold
    stain_lower = [0,0,0] / 255;
    stain_upper = [255,255,127] / 255;
    min_stain_area = 2000;

    % Define dirt threshold
    dirt_lower = [20,20,50] / 255;
    dirt_upper = [90,150,255] / 255;
    min_dirt_area = 2000;

    % Check if dominant color is within the dirt range
    is_dirt_colour = all(dominant_color >= dirt_lower) && all(dominant_color <= dirt_upper);
    is_dirt = is_dirt_colour && polyarea(boundary(:,2), boundary(:,1)) > min_dirt_area;

    if is_dirt
        stain_or_dirt = 'Dirt';
    else
        
        % Check if dominant color is within the stain range
        is_stain_colour = all(dominant_color >= stain_lower) && all(dominant_color <= stain_upper);
        is_stain = is_stain_colour && polyarea(boundary(:,2), boundary(:,1)) > min_stain_area;
        if is_stain
            stain_or_dirt = 'Stain';
        else
            stain_or_dirt = 'None';
        end
    end
end