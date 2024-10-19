function [boundaries, missing_finger, opening, ripped_edge, thins, containments, main_glove_contour, glove_convex_hull] = detect_defects(img)
    
    % Extract the main glove contour
    [glove_mask, main_glove_contour, glove_convex_hull] = threshold_glove(img);
    
    % Extract the contours in the glove
    boundaries = bwboundaries(glove_mask);
    
    % Detect missing fingers
    missing_finger = detect_missing_finger(img, main_glove_contour, glove_convex_hull);
    
    % Detect openings
    opening = detect_opening(main_glove_contour);
    
    ripped_edge = detect_ripped_edge(glove_mask);

    % Detect thins
    thins = detect_thin(glove_mask, img);

    % Detect containments
    containments = detect_containment(glove_mask, img);
end


