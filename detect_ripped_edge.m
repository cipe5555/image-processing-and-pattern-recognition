function inner_holes_properties = detect_ripped_edge(glove_mask)

    % Fill inner holes to the glove mask
    se = strel('disk', 10); 
    glove_mask_closed = imclose(glove_mask, se);
    glove_mask_filled = imfill(glove_mask_closed, 'holes');
    
    % Perform dilation on the filled glove mask to connect edges
    se = strel('disk', 13); 
    glove_mask_connected = imdilate(glove_mask_filled, se);
    
    % Perform erosion to refine the edges
    se2 = strel('disk', 13); 
    glove_mask_connected = imerode(glove_mask_connected, se2);
    
    % Perform dilation on the filled glove mask to connect edges
    se3 = strel('disk', 18); 
    glove_mask_connected = imdilate(glove_mask_connected, se3);
    
    % Fill holes in the glove_mask_closed
    glove_mask_filled = imfill(glove_mask_connected, 'holes');
    
    % Logical subtraction to detect inner holes
    inner_holes = glove_mask_filled & ~glove_mask_connected;
    
    % Find connected components in the inner holes mask
    inner_holes_components = bwconncomp(inner_holes);
    
    % Get region properties of inner holes
    inner_holes_properties = regionprops(inner_holes_components, 'BoundingBox');
end
