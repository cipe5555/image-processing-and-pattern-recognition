function openings = detect_opening(main_glove_contour)

    num_points = size(main_glove_contour, 1);

    % Calculate angles between consecutive segments
    angles = zeros(num_points - 2, 1);
    for i = 2:num_points-1
        vec1 = main_glove_contour(i,:) - main_glove_contour(i-1,:);
        vec2 = main_glove_contour(i+1,:) - main_glove_contour(i,:);

        % Compute the dot product and magnitudes
        dot_product = dot(vec1, vec2);
        magnitude1 = norm(vec1);
        magnitude2 = norm(vec2);

        % Compute the angle using the dot product formula
        angles(i-1) = acosd(dot_product / (magnitude1 * magnitude2));
    end
    
    % Define a threshold for identifying sudden changes in angle
    threshold_angle = 90;

    % Define a threshold distance to group changes together
    threshold_distance = 500;

    % Define a threshold for the minimum bounding box area
    threshold_area = 10000;
    
    % Find indices where angles is greater than the threshold
    change_indices = find(angles >= threshold_angle);

    % Group changes together
    grouped_changes = {};
    if ~isempty(change_indices)
        current_group = [change_indices(1)];
        for i = 2:length(change_indices)
            % Add to the current group if the distance is within the threshold
            if abs(change_indices(i) - current_group(end)) <= threshold_distance
                current_group = [current_group, change_indices(i)];
            else
                % Start a new group if the distance exceeds the threshold
                % Only add the group if it contains more than one change
                if length(current_group) > 1
                    grouped_changes = [grouped_changes, current_group];
                    current_group = [change_indices(i)];
                end
            end
        end

        % Add the last group if it contains more than one change
        if length(current_group) > 1
            grouped_changes = [grouped_changes, current_group];
        end
    end

    % % Initialize an empty array to store the openings
    openings = {};
    
    % Draw bounding boxes for each group
    for group_idx = 1:numel(grouped_changes)
        group = grouped_changes{group_idx};
        
        % Extract the contour points for the group
        group_contour = main_glove_contour(group,:);

        % Compute the centroid of the group contour
        group_centroid = mean(group_contour);

        width = max(group_contour(:,2)) - min(group_contour(:,2));
        height = max(group_contour(:,1)) - min(group_contour(:,1));

        % Calculate bounding box coordinates
        min_x = group_centroid(2) - width / 2;
        max_x = group_centroid(2) + width / 2;
        min_y = group_centroid(1) - height / 2;
        max_y = group_centroid(1) + height / 2;

         % Calculate the area of the bounding box
        bbox_area = (max_x - min_x) * (max_y - min_y);
        
        if bbox_area > threshold_area
            % Adjust the bounding box for display
            if bbox_area < 10000
                dx = max_x - min_x;
                dy = max_y - min_y;
                if dx > dy
                    % Scale height to match width
                    min_y = group_centroid(1) - dx / 2;
                    max_y = group_centroid(1) + dx / 2;
                else
                    % Scale width to match height
                    min_x = group_centroid(2) - dy / 2;
                    max_x = group_centroid(2) + dy / 2;
                end

                updated_bbox_area = (max_x - min_x) * (max_y - min_y);

                if updated_bbox_area < 5000
                    % Scale the bounding box
                    scaling_factor = sqrt(5000 / updated_bbox_area);

                    new_width = (max_x - min_x) * scaling_factor;
                    new_height = (max_y - min_y) * scaling_factor;

                    min_x = (max_x + min_x) / 2 - new_width / 2;
                    max_x = (max_x + min_x) / 2 + new_width / 2;
                    min_y = (max_y + min_y) / 2 - new_height / 2;
                    max_y = (max_y + min_y) / 2 + new_height / 2;
                end
            end

            openings = [openings, [min_x, min_y, max_x-min_x, max_y-min_y]];
        end
    end
end