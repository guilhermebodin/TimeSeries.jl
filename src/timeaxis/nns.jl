struct NearestNeighbors{T,P}
    k::Int
    c::T       # centroid
    r::P       # radius
    d::Symbol  # direction. :both, :forward, :backward
end


nns(; k = 1, c = nothing, radius, direction = :both) =
    NearestNeighbors(k, c, radius, direction)
