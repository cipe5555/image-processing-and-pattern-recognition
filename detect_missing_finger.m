function missing_finger = detect_missing_finger(image, main_glove_contour, glove_convex_hull)

    [~, finger_stats] = detect_skin_contour(image);

    % Extract the the x and y coordinates of the main glove contour
    glove_contour_x = main_glove_contour(:, 2);
    glove_contour_y = main_glove_contour(:, 1);
    
    % Find the centroid of the convex hull
    hull_centroid = [mean(glove_contour_x(glove_convex_hull)), mean(glove_contour_y(glove_convex_hull))];
    
    % Calculate distances between the points on the convex hull and the hull centroid
    distances = sqrt((glove_contour_x(glove_convex_hull) - hull_centroid(1)).^2 + (glove_contour_y(glove_convex_hull) - hull_centroid(2)).^2);
    
    % Define finger distance and spacing threshold
    min_distance_threshold = mean(distances) - 0.3 * mean(distances);
    max_distance_threshold = mean(distances) + 0.3 * mean(distances);
    min_spacing_threshold = 0.25 * mean(distances);
    
    % Initialize finger and curvature candidates
    finger_candidates = [];
    
    % Iterate through points on the convex hull
    for i = 1:numel(glove_convex_hull)
        current_index = glove_convex_hull(i);
        
        % Get the distance from current point to hull centroid
        distance_to_centroid = distances(i);
    
        % Check if the point is on the boundary of the image
        if glove_contour_x(current_index) == 1 || glove_contour_x(current_index) == size(image, 2) ...
            || glove_contour_y(current_index) == 1 || glove_contour_y(current_index) == size(image, 1)
            % Boundary points don't have curvature
            curvature = NaN;
        else
            % Extract the x and y coordinates of the points surrounding the selected point
            x = glove_contour_x(glove_convex_hull);
            y = glove_contour_y(glove_convex_hull);
        
            % Fit a polynomial curve to the points around the selected point
            poly_order = 2;
            fit_range = max(1, i - 5) : min(numel(glove_convex_hull), i + 5);
            p = polyfit(x(fit_range), y(fit_range), poly_order);
        
            % Evaluate the polynomial and its derivatives at the selected point
            % First derivative (y')
            y_prime = polyval(p, x(i), 1);
            % Second derivative (y'')
            y_double_prime = polyval(p, x(i), 2);
        
            % Calculate curvature using the formula: curvature = |y''| / (1 + y'^2)^(3/2)
            curvature = abs(y_double_prime) / (1 + y_prime^2)^(3/2);
            
            % Scale curvature by a factor
            curvature = curvature * 100000;
        end
    
        % Check if the current point is a finger candidate based on distance to hull centroid
        if distance_to_centroid >= min_distance_threshold && distance_to_centroid <= max_distance_threshold
            % Check if the point is sufficiently spaced from other fingers
            if isempty(finger_candidates) || ...
               all(sqrt((glove_contour_x(current_index) - glove_contour_x(finger_candidates)).^2 + ...
                        (glove_contour_y(current_index) - glove_contour_y(finger_candidates)).^2) > min_spacing_threshold)
                % Check if the current point is a finger candidate based on curvature
                if curvature >= 0.1
                    % Add the point as a finger candidate along with its curvature
                    finger_candidates = [finger_candidates, current_index];              
                end
            end
        end
    end

    % Calculate number of missing fingers
    num_missing_finger = max(0, 5 - numel(finger_candidates));

    % Initialization for storing the missing fingers
    distances = zeros(length(finger_stats), 1);
    missing_finger = [];

    % Check if there is any missing finger
    if num_missing_finger > 0
        for i = 1:length(finger_stats)

            % Extract bounding box centroid
            bbox_center = [finger_stats(i).BoundingBox(1) + finger_stats(i).BoundingBox(3)/2, ...
                           finger_stats(i).BoundingBox(2) + finger_stats(i).BoundingBox(4)/2];

            % Calculate the distance between the bounding box and hull centroid
            distances(i) = sqrt((hull_centroid(1) - bbox_center(1))^2 + (hull_centroid(2) - bbox_center(2))^2);
        end

        % Sort distances
        [~, sorted_indices] = sort(distances);

        % Select bounding boxes closest to the hull centroid
        closest_indices = [];
        for i = 1:numel(sorted_indices)
            current_index = sorted_indices(i);
            bbox_center = [finger_stats(current_index).BoundingBox(1) + finger_stats(current_index).BoundingBox(3)/2, ...
                           finger_stats(current_index).BoundingBox(2) + finger_stats(current_index).BoundingBox(4)/2];
            
            % Check if the bounding box is inside the main glove contour (It should not be inside if it is a missing finger)
            is_inside = inpolygon(bbox_center(2), bbox_center(1), main_glove_contour(:,1), main_glove_contour(:,2));

            % Check if the bounding box's area is larger than a finger area threshold
            if finger_stats(current_index).Area > 1200 && ~is_inside
                closest_indices = [closest_indices, sorted_indices(i)];
                if numel(closest_indices) == num_missing_finger
                    break;
                end
            end
        end

        % Extract corresponding stats of the missing fingers
        missing_finger = finger_stats(closest_indices);  
    end
end









