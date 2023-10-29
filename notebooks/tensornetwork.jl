### A Pluto.jl notebook ###
# v0.19.29

using Markdown
using InteractiveUtils

# ╔═╡ 24ef79e2-7674-11ee-2a55-c7205b55976b
using Pkg; Pkg.activate("..")

# ╔═╡ 2751eab0-f2b2-433e-a8b0-c0f58d14f719
using Revise

# ╔═╡ 8ce56be6-9ac9-4973-9723-993c09000107
using LuxorGraphPlot, Luxor

# ╔═╡ 0c3dbc41-a43f-4a7f-acd0-6609cb7e8b3b
@drawsvg begin
	radius = 30
	background("white")
	d = diagram() do
		for (loc, label) in [
				((0, 0), "A"),
				((0, 100), "B"),
				((100, 0), "C"),
				((100, 100), "D")
			]
			label!(ncircle!(loc, radius), label)
		end
		label!(nbox!((-100, -100), 30, 30; smooth=7), "7"),
		fontsize(28)
		connect!("A", "B", control_points=[tonode("C").loc, tonode("D").loc])
		connect!("C", "D", control_points=[tonode("A").loc, tonode("B").loc], isarrow=true, arrowprops=Dict(:finisharrow=>true, :linewidth=>2))
		cp = midpoint(tonode("A").loc, tonode("7").loc) + Point(-50, 50)
		connect!("A", "7")
		connect!("A", "7", control_points=[cp], smoothprops=Dict(:method=>"nosmooth"))
		connect!("A", "7", control_points=[cp], smoothprops=Dict(:method=>"smooth", :radius=>10))
		connect!("A", "7", control_points=[cp], smoothprops=Dict(:method=>"bezier", :radius=>10))
	end
	strokenodes(d)
	showlabels(d)
	setline(3)
	strokeconnections(d)
end 400 400

# ╔═╡ 0726cb97-6f95-498a-995a-00e5026fdddf
@drawsvg begin
	background("white")
	polysmooth([Point(0, 0), Point(0, 100), Point(100, 100), Point(100, 0)], 5, :stroke; close=false)
end 300 300

# ╔═╡ Cell order:
# ╠═24ef79e2-7674-11ee-2a55-c7205b55976b
# ╠═2751eab0-f2b2-433e-a8b0-c0f58d14f719
# ╠═8ce56be6-9ac9-4973-9723-993c09000107
# ╠═0c3dbc41-a43f-4a7f-acd0-6609cb7e8b3b
# ╠═0726cb97-6f95-498a-995a-00e5026fdddf
