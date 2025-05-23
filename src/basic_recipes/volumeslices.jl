
"""
    volumeslices(x, y, z, v)

Draws heatmap slices of the volume v
"""
@recipe VolumeSlices (x, y, z, volume) begin
    MakieCore.documented_attributes(Heatmap)...
    bbox_visible = true
    bbox_color = RGBAf(0.5, 0.5, 0.5, 0.5)
end

function Makie.plot!(plot::VolumeSlices)
    @extract plot (x, y, z, volume)
    replace_automatic!(plot, :colorrange) do
        lift(extrema, plot, volume)
    end

    # heatmap will fail if we don't keep its attributes clean
    attr = copy(Attributes(plot))
    bbox_color = pop!(attr, :bbox_color)
    bbox_visible = pop!(attr, :bbox_visible)
    pop!(attr, :model) # stops `transform!()` from working

    bbox = lift(plot, x, y, z) do x, y, z
        mx, Mx = extrema(x)
        my, My = extrema(y)
        mz, Mz = extrema(z)
        Rect3(mx, my, mz, Mx-mx, My-my, Mz-mz)
    end

    axes = :x, :y, :z
    for (ax, p, r, (X, Y)) ∈ zip(axes, (:yz, :xz, :xy), (x, y, z), ((y, z), (x, z), (x, y)))
        plot[Symbol(:heatmap_, p)] = hmap = heatmap!(
            plot, attr, X, Y, zeros(length(X[]), length(Y[]))
        )
        plot[Symbol(:update_, p)] = update = i -> begin
            transform!(hmap, (p, r[][i]))
            indices = ntuple(Val(3)) do j
                axes[j] == ax ? i : (:)
            end
            hmap[3][] = view(volume[], indices...)
        end
        update(1) # trigger once to place heatmaps correctly
    end

    linesegments!(plot, bbox, color = bbox_color, visible = bbox_visible, inspectable = false)

    plot
end
