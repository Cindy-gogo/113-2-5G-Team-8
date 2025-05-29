function count = isPathBlocked(p1, p2, walls)
    count = 0;
    for i = 1:length(walls)
        w = walls{i};
        if segmentsIntersect(p1, p2, w(1:2), w(3:4))
            count = count + 1;
        end
    end
end

function tf = segmentsIntersect(p1, p2, q1, q2)
    tf = ccw(p1, q1, q2) ~= ccw(p2, q1, q2) && ccw(p1, p2, q1) ~= ccw(p1, p2, q2);
end

function val = ccw(a,b,c)
    val = (c(2)-a(2))*(b(1)-a(1)) > (b(2)-a(2))*(c(1)-a(1));
end