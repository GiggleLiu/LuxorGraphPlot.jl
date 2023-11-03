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

# ╔═╡ 6dcfc6e3-8c53-4614-9681-c7e2dd3d05d1
using LuxorGraphPlot.TensorNetwork

# ╔═╡ 00bee32e-651b-43d7-89ec-40e89d691127
using LaTeXStrings, MathTeXEngine

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
			label!(circle!(loc, radius), label)
		end
		label!(box!((-100, -100), 30, 30; smooth=7), "7"),
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

# ╔═╡ cef5c3a5-ab75-4ea5-bd8e-3c00d706d1fb
figdiagram(250, 200) do
	m = ["o" "o" "o";
		"□" "□" "□";
		"o" "o" "o"]
	nodes = grid!(m; size=10, offset=(50, 50), hspace=70)
	for j=1:3
		connect!(nodes[1, j], nodes[2, j])
		connect!(nodes[3, j], nodes[2, j])
	end
	for j=1:2
		connect!(nodes[2, j], nodes[2, j+1])
	end
	cc!(nodes[1, 1], nodes[3, 1], "left")
	cc!(nodes[1, 3], nodes[3, 3], "right")
	fill.(nodes[2,:])
end

# ╔═╡ fe8b633b-b3f1-426d-8c6d-84be934a53e4
function simplegriddiagram(m, n, node_list, edge_list)
	vspace = hspace = 50
	mat = fill(".", m, n)
	for (i, j) in node_list
		mat[i, j] = "o"
	end
	figdiagram(vspace * (n + 1), hspace * (m + 1)) do
		nodes = grid!(mat; size=10, offset=(50, 50))
		render(x) = x isa Vector ? nodes[x...] : nodes[node_list[x]...]
		for (i, j) in edge_list
			a, b = render(i), render(j)
			if a.shape == :dot
				a = offset(a, b, 20)
			end
			if b.shape == :dot
				b = offset(b, a, 20)
			end
			connect!(a, b)
		end
	end
end

# ╔═╡ 7eb82963-8408-4fab-928f-1eaaf5c92d96
simplegriddiagram(3, 3, [(1, 1), (1, 2), (2, 3), (3, 3)], [(1, 2), (2, 3), (3, 4)])

# ╔═╡ 3035641f-8ddf-4acc-b1b8-d010e9a6a724
simplegriddiagram(1, 4, [(1, 2), (1, 3)], [([1, 1], 1), (1, 2), (2, [1, 4])])

# ╔═╡ 05e26bca-edb5-466b-a3be-946392c2bbf5
md"evolve"

# ╔═╡ 2edf78f1-e444-4b57-83f9-fd48d2f93126
@drawsvg begin
	origin(0, 0)
	x1 = 100
	x2 = 200
	xmid = 150
	y1 = 100
	y2 = 200
	y3 = 300
	boxsize = 50
	ctext(txt, pos) = text(txt, pos, valign=:middle, halign=:center)
	background("white")
	dd = diagram() do
		ll = label!(box!((xmid, y1), 150, 50), "exp(i L ⊗ L)")
		topleft = box!((x1, y2), boxsize, boxsize; smooth=5)
		topright = box!((x2, y2), boxsize, boxsize)
		bottomleft = box!((x1, y3), boxsize, boxsize)
		bottomright = box!((x2, y3), boxsize, boxsize)
		cc!(topleft, ll, "left", offsetrate=0.8)
		cc!(topright, ll, "right")
		connect!(topleft, bottomleft)
		connect!(topright, bottomright)
		connect!(topleft, topright)
		connect!(bottomleft, bottomright)
		dangle!(bottomleft, "left", 70)
		dangle!(bottomright, "right", 70)
		fontsize(18)
		ctext(L"e^{iL \otimes L^\dagger}", ll.loc)
		ctext(L"A", topleft.loc)
		ctext(L"A^\dagger", topright.loc)
		ctext(L"B", bottomleft.loc)
		ctext(L"B^\dagger", bottomright.loc)
	end
	strokenodes(dd)
	strokeconnections(dd)
	#showlabels(dd)
end 300 400

# ╔═╡ Cell order:
# ╠═24ef79e2-7674-11ee-2a55-c7205b55976b
# ╠═2751eab0-f2b2-433e-a8b0-c0f58d14f719
# ╠═8ce56be6-9ac9-4973-9723-993c09000107
# ╠═0c3dbc41-a43f-4a7f-acd0-6609cb7e8b3b
# ╠═0726cb97-6f95-498a-995a-00e5026fdddf
# ╠═6dcfc6e3-8c53-4614-9681-c7e2dd3d05d1
# ╠═cef5c3a5-ab75-4ea5-bd8e-3c00d706d1fb
# ╠═fe8b633b-b3f1-426d-8c6d-84be934a53e4
# ╠═7eb82963-8408-4fab-928f-1eaaf5c92d96
# ╠═3035641f-8ddf-4acc-b1b8-d010e9a6a724
# ╟─05e26bca-edb5-466b-a3be-946392c2bbf5
# ╠═00bee32e-651b-43d7-89ec-40e89d691127
# ╠═2edf78f1-e444-4b57-83f9-fd48d2f93126
