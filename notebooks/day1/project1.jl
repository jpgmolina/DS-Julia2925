### A Pluto.jl notebook ###
# v0.12.17

using Markdown
using InteractiveUtils

# ╔═╡ c962de82-3c9e-11eb-13df-d5dec37bb2c0
using CSV, DataFrames, Dates

# ╔═╡ 485292d8-2bde-11eb-0a97-6b44d54596dd
using Plots

# ╔═╡ fc8ff7b8-2be1-11eb-0c9c-b9d2ee7c2880
using Markdown, Images

# ╔═╡ 2411c6ca-2bdd-11eb-050c-0399b3b0d7af
md"""
# Project 1: images and cellular automata

We wrap up the day by exploring convolutions and similar operations on 1-D and 2-D (or even n-D!) matrices. Departing from some basic building blocks we will cover signal processing, image processing and cellular automata!

Learning goals:
- code reuse;
- speed and performance (including optimizations);
- learning to plot and make animations.
"""

# ╔═╡ 14bb9c3a-34b5-11eb-0f20-75a14b584e0c
matrix = [1 2 3 4; 5 6 7 8; 9 10 11 12]

# ╔═╡ 2712ade2-34b5-11eb-0242-57f37f6607a3
C = CartesianIndices(matrix)

# ╔═╡ 3d9c3fea-2bde-11eb-0f09-cf11dcb07c0d
md"""
## 1-D operations

We will start with local operations in 1-D, i.e., processing a vector to obtain a new vector. Such operations are important in signal processing, for example, if we want to smoothen a noisy signal but are also used in bioinformatics and complex systems. 
"""

# ╔═╡ e1147d4e-2bee-11eb-0150-d7af1f51f842
md"""
### 1-D convolution

Convolution:

$$y_i = \sum_{k=-m}^{m} x_{i + k} w_{m+k+1}$$

Boundary effects.
"""

# ╔═╡ 3df9e7dc-4833-11eb-2794-35241b41c93f
md"""A one-dimensional convolution can be seen as a *local weighted average* of a vector:
- local means that, for each element of the output, we only consider a small subregion of our input vector;
- weighted average means that within this region, we might not give every element an equal importance.

Let us first consider the vanilla mean:

$$\frac{1}{n}\sum_{i=1}^n x_i\,.$$

The function `mean` is not in the `Base` of Julia but can easily be imported from `StatsBase`. Let's implement it ourselves instead!
"""

# ╔═╡ f272855c-3c9e-11eb-1919-6b7301b15699
function mean(x)
	n = length(x)
	return sum(x) / n
end

# ╔═╡ 66a20628-4834-11eb-01a2-27cc2b1ec7be
x = [2.1, 3.2, 5.4, 4.9, 6.1]

# ╔═╡ 432c3892-482c-11eb-1467-a3b9c1592597
mean(x)

# ╔═╡ 8b220aea-4834-11eb-12bb-3b91414fe30a
md"""
So, in this regular mean, we give an equal weight to every element: every $x_i$ is equally important in determining the mean. In some cases, however, we know that some positions are more important than others in determining the mean. For example, we might know the measurement error and might given a weigth inversly proportional to the error. The weigted mean is computed as:

$$\sum_{i=1}^n w_ix_i\,,$$

were, $w_i$ are the weights. In order for the weighted mean to make sense, we assume that all these weights are non-zero and that they sum to 1.

Implement the weighted mean.
"""

# ╔═╡ 88c10640-4835-11eb-14b0-abba18da058f
weighted_mean(x, w) = sum(x .* w)

# ╔═╡ a657c556-4835-11eb-12c3-398890e70105
md"We compute the mean again, now using the information that the numbers were collected consequently and that we give a weight linearly proportional to the position."

# ╔═╡ 181c4246-4836-11eb-0368-61b2998f5424
wx = collect((1:5) / sum(1:5))

# ╔═╡ 94a950fe-4835-11eb-029c-b70de72c20e6
weighted_mean(x, wx)

# ╔═╡ 52706c6a-4836-11eb-09a8-53549f16f5c2
md"Note that:"

# ╔═╡ 4dc28cdc-4836-11eb-316f-43c04639da2a
sum(wx)

# ╔═╡ 8b4c6880-4837-11eb-0ff7-573dd18a9664


# ╔═╡ 31e39938-3c9f-11eb-0341-53670c2e93e1
begin
download("https://epistat.sciensano.be/Data/COVID19BE_CASES_AGESEX.csv", "COVID19BE_CASES_AGESEX.csv")
covid_data = CSV.read("COVID19BE_CASES_AGESEX.csv")
covid_data = combine(groupby(covid_data, :DATE), :CASES=>sum)
end

# ╔═╡ caef0432-3c9f-11eb-2006-8ff54211b2b3
covid_cases = covid_data[1:end-1,2]

# ╔═╡ b3ec8362-482d-11eb-2df4-2343ee17444a
covid_dates = [Date(d, "yyyy-mm-dd") for d in covid_data[1:end-1,1]]

# ╔═╡ 8a996336-2bde-11eb-10a3-cb0046ed5de9
plot(covid_dates, covid_cases, label="measured COVID cases in Belgium")

# ╔═╡ a1f75f4c-2bde-11eb-37e7-2dc342c7032a
function convolve_1d(x::Vector, w::Vector)
	@assert length(w) % 2 == 1 "length of `w` has to be odd!"
	n = length(x)
	m = div(length(w), 2)
	out = zeros(n)

	fill!(out, 0.0)
	for (i, xj) in enumerate(x)
		for (j, wj) in enumerate(w)
			k = clamp(i + j - m, 1, n)
			out[i] += w[j] * x[k]
		end
	end
	return out
end

# ╔═╡ ef84b6fe-2bef-11eb-0943-034b8b90c4c4
function uniform_weights(m)
	return ones(2m+1) / (2m+1)
end

# ╔═╡ 294140a4-2bf0-11eb-22f5-858969a4640d
function triangle_weigths(m)
	w = zeros(2m+1)
	for i in 1:(m+1)
		w[i] = i
		w[end-i+1] = i
	end
	w ./= sum(w)
	return w
end	

# ╔═╡ fa911a76-2be3-11eb-1c85-3df313eb0fcb
w = triangle_weigths(9)

# ╔═╡ 20c46656-2bf0-11eb-2dc4-af2cc2161f6a
scatter(w, xlabel="j", ylabel="weight")

# ╔═╡ cb5f4a20-2be8-11eb-0000-c59f23a024ef
signal_c = convolve_1d(covid_cases, w)

# ╔═╡ eb5f8062-2be1-11eb-1e96-1f89be62f3b0
plot(covid_dates, signal_c)

# ╔═╡ af33214a-2be7-11eb-34f5-0d046c9db735
function generalized_convolve_1d!(x, out, m, f)
	n = length(x)
	@assert n == length(out) "`x` and `out` have to be of the same length!"
	fill!(out, 0.0)
	for (i, xj) in enumerate(x)
		if  m < i < n - m
			out[i] = f(x[(i-m):(i+m)])
		else
			out[i] = 0#x[i]
		end
	end
	return out
end

# ╔═╡ 4263e920-2bf1-11eb-1db1-ed644a480a2d


# ╔═╡ 21ce0552-2be9-11eb-2359-152a7c75cc2e
vec_conv(x_s) = sum(x_s .* w)

# ╔═╡ b7ba4ed8-2bf1-11eb-24ee-731940d1c29f
md"""
### Sliding window: secundary structure prediction

Chou-Fasman method
"""

# ╔═╡ 5c20f87e-3ca1-11eb-3a21-27790a167ca5
zdict = Dict(
		'A' => [0.24,  -2.32,  0.60, -0.14,  1.30], # A
		'C' => [0.84,  -1.67,  3.71,  0.18, -2.65], # C
		'D' => [3.98,   0.93,  1.93, -2.46,  0.75], # D
		'E' => [3.11,   0.26, -0.11, -0.34, -0.25], # E
		'F' => [-4.22,  1.94,  1.06,  0.54, -0.62], # F
		'G' => [2.05,  -4.06,  0.36, -0.82, -0.38], # G
		'H' => [2.47,   1.95,  0.26,  3.90,  0.09], # H
		'I' => [-3.89, -1.73, -1.71, -0.84,  0.26], # I
		'K' => [2.29,   0.89, -2.49,  1.49,  0.31], # K
		'L' => [-4.28, -1.30, -1.49, -0.72,  0.84], # L
		'M' => [-2.85, -0.22,  0.47,  1.94, -0.98], # M
		'N' => [3.05,   1.62,  1.04, -1.15,  1.61], # N
		'P' => [-1.66,  0.27,  1.84,  0.70,  2.00], # P
		'Q' => [1.75,   0.50, -1.44, -1.34,  0.66], # Q
		'R' => [3.52,   2.50, -3.50,  1.99, -0.17], # R
		'S' => [2.39,  -1.07,  1.15, -1.39,  0.67], # S
		'T' => [0.75,  -2.18, -1.12, -1.46, -0.40], # T
		'V' => [-2.59, -2.64, -1.54, -0.85, -0.02], # V
		'W' => [-4.36,  3.94,  0.59,  3.44, -1.59], # W
		'Y' => [-2.54,  2.44,  0.43,  0.04, -1.47], # Y
	)

# ╔═╡ 87610484-3ca1-11eb-0e74-8574e946dd9f
zscales1 = Dict(A=>z[1] for (A, z) in zdict)

# ╔═╡ 9c82d5ea-3ca1-11eb-3575-f1893df8f129
zscales2 = Dict(A=>z[2] for (A, z) in zdict)

# ╔═╡ a4ccb496-3ca1-11eb-0e7a-87620596eec1
zscales3 = Dict(A=>z[3] for (A, z) in zdict)

# ╔═╡ c924a5f6-2bf1-11eb-3d37-bb63635624e9
spike_sars2 = "MFVFLVLLPLVSSQCVNLTTRTQLPPAYTNSFTRGVYYPDKVFRSSVLHSTQDLFLPFFSNVTWFHAIHVSGTNGTKRFDNPVLPFNDGVYFASTEKSNIIRGWIFGTTLDSKTQSLLIVNNATNVVIKVCEFQFCNDPFLGVYYHKNNKSWMESEFRVYSSANNCTFEYVSQPFLMDLEGKQGNFKNLREFVFKNIDGYFKIYSKHTPINLVRDLPQGFSALEPLVDLPIGINITRFQTLLALHRSYLTPGDSSSGWTAGAAAYYVGYLQPRTFLLKYNENGTITDAVDCALDPLSETKCTLKSFTVEKGIYQTSNFRVQPTESIVRFPNITNLCPFGEVFNATRFASVYAWNRKRISNCVADYSVLYNSASFSTFKCYGVSPTKLNDLCFTNVYADSFVIRGDEVRQIAPGQTGKIADYNYKLPDDFTGCVIAWNSNNLDSKVGGNYNYLYRLFRKSNLKPFERDISTEIYQAGSTPCNGVEGFNCYFPLQSYGFQPTNGVGYQPYRVVVLSFELLHAPATVCGPKKSTNLVKNKCVNFNFNGLTGTGVLTESNKKFLPFQQFGRDIADTTDAVRDPQTLEILDITPCSFGGVSVITPGTNTSNQVAVLYQDVNCTEVPVAIHADQLTPTWRVYSTGSNVFQTRAGCLIGAEHVNNSYECDIPIGAGICASYQTQTNSPRRARSVASQSIIAYTMSLGAENSVAYSNNSIAIPTNFTISVTTEILPVSMTKTSVDCTMYICGDSTECSNLLLQYGSFCTQLNRALTGIAVEQDKNTQEVFAQVKQIYKTPPIKDFGGFNFSQILPDPSKPSKRSFIEDLLFNKVTLADAGFIKQYGDCLGDIAARDLICAQKFNGLTVLPPLLTDEMIAQYTSALLAGTITSGWTFGAGAALQIPFAMQMAYRFNGIGVTQNVLYENQKLIANQFNSAIGKIQDSLSSTASALGKLQDVVNQNAQALNTLVKQLSSNFGAISSVLNDILSRLDKVEAEVQIDRLITGRLQSLQTYVTQQLIRAAEIRASANLAATKMSECVLGQSKRVDFCGKGYHLMSFPQSAPHGVVFLHVTYVPAQEKNFTTAPAICHDGKAHFPREGVFVSNGTHWFVTQRNFYEPQIITTDNTFVSGNCDVVIGIVNNTVYDPLQPELDSFKEELDKYFKNHTSPDVDLGDISGINASVVNIQKEIDRLNEVAKNLNESLIDLQELGKYEQYIKWPWYIWLGFIAGLIAIVMVTIMLCCMTSCCSCLKGCCSCGSCCKFDEDDSEPVLKGVKLHYT"

# ╔═╡ c02be52e-301a-11eb-37f6-2fa27211a76e
function chou_fasman(sequence, windowsize, pars)
	f_cf(subseq) = mean((pars[s] for s in subseq))
	out = zeros(length(sequence))
	return generalized_convolve_1d!(sequence, out, windowsize, f_cf)
end

# ╔═╡ c23ff59c-3ca1-11eb-1a31-2dd522b9d239
protein_z_scale1 = [zscales1[AA] for AA in spike_sars2]

# ╔═╡ dce6ec82-3ca1-11eb-1d87-1727b0e692df
plot(convolve_1d(protein_z_scale1, w))

# ╔═╡ 4e6dedf0-2bf2-11eb-0bad-3987f6eb5481
md"""
### Elementary cellular automata
"""

# ╔═╡ b03c60f6-2bf3-11eb-117b-0fc2a259ffe6
rule = 110 |> UInt8

# ╔═╡ a6e7441a-482e-11eb-1edb-6bd1daa00390
bitstring(rule)

# ╔═╡ b43157fa-482e-11eb-3169-cf4989528800


# ╔═╡ 625c4e1e-2bf3-11eb-2c03-193f7d013fbe
begin
	
nextstate(l::Bool, s::Bool, r::Bool, rule::Int) = nextstate(l, s, r, UInt8(rule))

function nextstate(l::Bool, s::Bool, r::Bool, rule::UInt8)
	bitstring(rule)[8-(4r+2s+1r)] == '1';
end
	
end

# ╔═╡ 5f97da58-2bf4-11eb-26de-8fc5f19f02d2
Dict(Gray.([l, s, r]) => Gray(nextstate(l, s, r, rule))
	for l in [true, false]
	for s in [true, false]
	for r in [true, false]
				)
										

# ╔═╡ 4776ccca-482f-11eb-1194-398046ab944a
Dict((l, s, r) => nextstate(l, s, r, rule)
	for l in [true, false]
	for s in [true, false]
	for r in [true, false]
				)
					

# ╔═╡ 924461c0-2bf3-11eb-2390-71bad2541463
function update1dca!(xnew, x, rule::UInt8)
	n = length(x)
	xnew[1] = nextstate(x[end], x[1], x[2], rule)
	xnew[end] = nextstate(x[end-1], x[end], x[1], rule)
	for i in 2:n-1
		xnew[i] = nextstate(x[i-1], x[i], x[i+1], rule)
	end
	return xnew
end

# ╔═╡ 21440956-2bf5-11eb-0860-11127d727282
next1dca(x, rule::UInt8) = update1dca!(similar(x), x, rule::UInt8)

# ╔═╡ 405a1036-2bf5-11eb-11f9-a1a714dbf7e1
x0_ca = rand(Bool, 500)

# ╔═╡ 6405f574-2bf5-11eb-3656-d7b9c94f145a
next1dca(x0_ca, rule)

# ╔═╡ 756ef0e0-2bf5-11eb-107c-8d1c65eacc45
"""
    simulate(x0, rule; nsteps=100)

Simulate `nsteps` time steps according to `rule` with `X0` as the initial condition.
Returns a matrix X, where the rows are the state vectors at different time steps.
"""
function simulate(x0, rule::UInt8; nsteps=100)
	n = length(x0)
    X = zeros(Bool, nsteps+1, n)
	X[1,:] = x0
	for t in 1:nsteps
		x = @view X[t,:]
		xnew = @view X[t+1,:]
		update1dca!(xnew, x, rule)
	end
    return X
end

# ╔═╡ e1dd7abc-2bf5-11eb-1f5a-0f46c7405dd5
X = simulate(x0_ca, rule; nsteps=200)

# ╔═╡ 9dbb9598-2bf6-11eb-2def-0f1ddd1e6b10
show_ca(X) = Gray.(X)

# ╔═╡ fb9a97d2-2bf5-11eb-1b92-ab884f0014a8
plot(show_ca(X))

# ╔═╡ 4810a052-2bf6-11eb-2e9f-7f9389116950
all_cas = Dict(rule=>show_ca(simulate(x0_ca, rule; nsteps=500)) for rule in UInt8(0):UInt8(251))

# ╔═╡ 47e3c2f8-2bf6-11eb-1fbf-d5f3fc899056
all_cas[3] |> plot

# ╔═╡ aea84d6c-2be3-11eb-2fe7-63e0d0c28507
keep_working(text=md"The answer is not quite right.") = Markdown.MD(Markdown.Admonition("correct", "Keep working on it!", [text]))

# ╔═╡ dc2230ac-2be3-11eb-24d7-f980be57d697
keep_working()

# ╔═╡ 41e7ef30-2be4-11eb-1b9a-e7f7eae7a115
philip_file = download("https://i.imgur.com/VGPeJ6s.jpg")

# ╔═╡ 473c581c-2be5-11eb-1ddc-2d30a3468c8a
decimate(image, ratio=5) = image[1:ratio:end, 1:ratio:end]

# ╔═╡ 4c9d2e0e-2be4-11eb-2fb3-377f29141076
philip = let
	original = Images.load(philip_file)
	decimate(original, 8)
end

# ╔═╡ 608e930e-2bfc-11eb-09f2-29600cfba1e6
function convolve_2d!(M::AbstractMatrix, out::AbstractMatrix, K::AbstractMatrix)
	n_rows, n_cols = size(M)
	fill!(out, 0.0)
	m = div(size(K, 1), 2) 
	for i in 1:n_rows
		for j in 1:n_cols
			for k in -m:m
				for l in -m:m
					out[i,j] += M[clamp(i+k, 1, n_rows), clamp(j+l, 1, n_cols)] * K[k+m+1,l+m+1]
				end
			end
		end
	end
	return out
end

# ╔═╡ 245deb30-2bfe-11eb-3e47-6b7bd5d73ccf
function gaussian_kernel(m; σ)
	K = [exp(-(x^2 + y^2) / σ^2) for x in -m:m, y in -m:m]
	K ./= sum(K)
	return K
end

# ╔═╡ 6278ae28-2bfe-11eb-3c36-9bf8cc703a3a
K = gaussian_kernel(2, σ=10)

# ╔═╡ 6c40b89c-2bfe-11eb-3593-9d9ef6f45b80
heatmap(K)

# ╔═╡ 73c3869a-2bfd-11eb-0597-29cd6c1c90db
convolve_2d(M, K) = convolve_2d!(M, similar(M), K) 

# ╔═╡ a34f1e4c-2bfd-11eb-127e-295a7039c301
convolve_2d(randn(1000, 1000), K)

# ╔═╡ c80e4362-2bfe-11eb-2055-5fbf167be551
K_sharpen = [0 -1 0;
			-1 5 -1;
			0 -1 0]

# ╔═╡ 84880dfc-2bfd-11eb-32b7-47750e1c696b
function convolve_image(M, K)
	Mred = convolve_2d(red.(M), K)
	Mgreen = convolve_2d(green.(M), K)
	Mblue = convolve_2d(blue.(M), K)
	return RGB.(Mred, Mgreen, Mblue)
end

# ╔═╡ 8c62855a-2bff-11eb-00f5-3702e142f76f
const Gx = [1 0 -1;
		   2 0 -2;
		   1 0 -1]

# ╔═╡ ae8d6258-2bff-11eb-0182-afc33d9d4efc
const Gy = [1 2 1;
		    0 0 0;
		   -1 -2 -1]

# ╔═╡ 746d3578-2bff-11eb-121a-f3d17397a49e
function edge_detection(M)
	M = Gray.(M) .|> Float64
	return convolve_2d(M, Gx).^2 + convolve_2d(M, Gy).^2 .|> Gray
end

# ╔═╡ f41919a4-2bff-11eb-276f-a5edd5b374ac
edge_detection(philip)

# ╔═╡ e1f23724-2bfd-11eb-1063-1d59909bcacc
convolve_image(philip, K)

# ╔═╡ 55bfb46a-2be5-11eb-2be6-1bc153db11ac
RGB.(red.(philip), green.(philip), blue.(philip))

# ╔═╡ 04f3c460-2bed-11eb-1039-238bfb3ec445
images = [rand([RGB(0, 0, 1),RGB(1, 0, 0)], 50, 100) for i in 1:100]

# ╔═╡ b3eed0e0-2bed-11eb-21d3-19323b600edf
images[1]

# ╔═╡ d523e4c6-301b-11eb-040a-f7a214cb785b
function count_neighbors((i, j), grid::Matrix{Bool})
	n_neighbors = grid[i+1,j+1] + grid[i+1,j] +
						grid[i+1,j-1] + grid[i,j-1] +
						grid[i-1, j-1] + grid[i-1,j] +
						grid[i-1,j+1] + grid[i, j+1]
	return n_neighbors
end

# ╔═╡ fafc7e74-34c6-11eb-0ce1-8fe2e3215739
function cell_state((i, j), grid::Matrix{Bool})
	return grid[i,j]
end

# ╔═╡ 0f7f9156-34c7-11eb-01dd-db5b3e1b0eca
function next_state((i, j), grid::Matrix{Bool})
	state = cell_state((i, j), grid)
	n_neighbors = count_neighbors((i, j), grid)
	next_state =  (state && (2 ≤ n_neighbors ≤ 3)) || # staying alive
				(!state && n_neighbors == 3)
	return next_state
end

# ╔═╡ 9c7ad77a-34c7-11eb-0636-5d4c8dd9542b
function next_gol!(grid, new_grid)
	n, m = size(grid)
	for j in 1:m
		for i in 1:m
			if 1 < i < n && 1 < j < m
				new_grid[i,j] = next_state((i, j), grid)
			else
				new_grid[i,j] = false
			end
		end
	end
	grid .= new_grid
	return grid
end

# ╔═╡ 24e09632-34ca-11eb-09c6-cd0a14601723
function update_gol!(grid; nsteps=1)
	new_grid = similar(grid)
	for t in 1:nsteps
		next_gol!(grid, new_grid)
	end
	return grid
end

# ╔═╡ ac4540e6-34ca-11eb-28a5-39a639f385a1
md"Updates via hashing, how many needed for all 3x3 grids"

# ╔═╡ 1937de5a-34c8-11eb-0a99-afc09e510273
grid = rand(Bool, 50, 50)

# ╔═╡ 47a40a70-34c8-11eb-2ae1-5fde1e1ef83c
new_grid = zero(grid)

# ╔═╡ a35eda0c-34c8-11eb-27e4-35a06de2df43
(next_gol!(grid, new_grid) for i in 1:1000)

# ╔═╡ 54e78bb0-34c8-11eb-0cf9-a1a2b398e107
@gif for i ∈ 1:100
		next_gol!(grid, new_grid)
		#grid, new_grid = new_grid, grid
		plot(show_ca(grid))
end

# ╔═╡ Cell order:
# ╠═2411c6ca-2bdd-11eb-050c-0399b3b0d7af
# ╠═14bb9c3a-34b5-11eb-0f20-75a14b584e0c
# ╠═2712ade2-34b5-11eb-0242-57f37f6607a3
# ╠═3d9c3fea-2bde-11eb-0f09-cf11dcb07c0d
# ╠═e1147d4e-2bee-11eb-0150-d7af1f51f842
# ╠═3df9e7dc-4833-11eb-2794-35241b41c93f
# ╠═f272855c-3c9e-11eb-1919-6b7301b15699
# ╠═66a20628-4834-11eb-01a2-27cc2b1ec7be
# ╠═432c3892-482c-11eb-1467-a3b9c1592597
# ╠═8b220aea-4834-11eb-12bb-3b91414fe30a
# ╠═88c10640-4835-11eb-14b0-abba18da058f
# ╠═a657c556-4835-11eb-12c3-398890e70105
# ╠═181c4246-4836-11eb-0368-61b2998f5424
# ╠═94a950fe-4835-11eb-029c-b70de72c20e6
# ╠═52706c6a-4836-11eb-09a8-53549f16f5c2
# ╠═4dc28cdc-4836-11eb-316f-43c04639da2a
# ╠═8b4c6880-4837-11eb-0ff7-573dd18a9664
# ╠═c962de82-3c9e-11eb-13df-d5dec37bb2c0
# ╠═31e39938-3c9f-11eb-0341-53670c2e93e1
# ╠═caef0432-3c9f-11eb-2006-8ff54211b2b3
# ╠═b3ec8362-482d-11eb-2df4-2343ee17444a
# ╠═8a996336-2bde-11eb-10a3-cb0046ed5de9
# ╠═485292d8-2bde-11eb-0a97-6b44d54596dd
# ╠═a1f75f4c-2bde-11eb-37e7-2dc342c7032a
# ╠═fa911a76-2be3-11eb-1c85-3df313eb0fcb
# ╠═20c46656-2bf0-11eb-2dc4-af2cc2161f6a
# ╠═cb5f4a20-2be8-11eb-0000-c59f23a024ef
# ╠═eb5f8062-2be1-11eb-1e96-1f89be62f3b0
# ╠═ef84b6fe-2bef-11eb-0943-034b8b90c4c4
# ╠═294140a4-2bf0-11eb-22f5-858969a4640d
# ╠═af33214a-2be7-11eb-34f5-0d046c9db735
# ╠═4263e920-2bf1-11eb-1db1-ed644a480a2d
# ╠═21ce0552-2be9-11eb-2359-152a7c75cc2e
# ╠═b7ba4ed8-2bf1-11eb-24ee-731940d1c29f
# ╠═5c20f87e-3ca1-11eb-3a21-27790a167ca5
# ╠═87610484-3ca1-11eb-0e74-8574e946dd9f
# ╠═9c82d5ea-3ca1-11eb-3575-f1893df8f129
# ╠═a4ccb496-3ca1-11eb-0e7a-87620596eec1
# ╠═c924a5f6-2bf1-11eb-3d37-bb63635624e9
# ╠═c02be52e-301a-11eb-37f6-2fa27211a76e
# ╠═c23ff59c-3ca1-11eb-1a31-2dd522b9d239
# ╠═dce6ec82-3ca1-11eb-1d87-1727b0e692df
# ╠═4e6dedf0-2bf2-11eb-0bad-3987f6eb5481
# ╠═b03c60f6-2bf3-11eb-117b-0fc2a259ffe6
# ╠═a6e7441a-482e-11eb-1edb-6bd1daa00390
# ╠═b43157fa-482e-11eb-3169-cf4989528800
# ╠═625c4e1e-2bf3-11eb-2c03-193f7d013fbe
# ╠═5f97da58-2bf4-11eb-26de-8fc5f19f02d2
# ╠═4776ccca-482f-11eb-1194-398046ab944a
# ╠═924461c0-2bf3-11eb-2390-71bad2541463
# ╠═21440956-2bf5-11eb-0860-11127d727282
# ╠═405a1036-2bf5-11eb-11f9-a1a714dbf7e1
# ╠═6405f574-2bf5-11eb-3656-d7b9c94f145a
# ╠═756ef0e0-2bf5-11eb-107c-8d1c65eacc45
# ╠═e1dd7abc-2bf5-11eb-1f5a-0f46c7405dd5
# ╠═9dbb9598-2bf6-11eb-2def-0f1ddd1e6b10
# ╠═fb9a97d2-2bf5-11eb-1b92-ab884f0014a8
# ╠═4810a052-2bf6-11eb-2e9f-7f9389116950
# ╠═47e3c2f8-2bf6-11eb-1fbf-d5f3fc899056
# ╠═fc8ff7b8-2be1-11eb-0c9c-b9d2ee7c2880
# ╠═aea84d6c-2be3-11eb-2fe7-63e0d0c28507
# ╠═dc2230ac-2be3-11eb-24d7-f980be57d697
# ╠═41e7ef30-2be4-11eb-1b9a-e7f7eae7a115
# ╠═4c9d2e0e-2be4-11eb-2fb3-377f29141076
# ╠═473c581c-2be5-11eb-1ddc-2d30a3468c8a
# ╠═608e930e-2bfc-11eb-09f2-29600cfba1e6
# ╠═245deb30-2bfe-11eb-3e47-6b7bd5d73ccf
# ╠═6278ae28-2bfe-11eb-3c36-9bf8cc703a3a
# ╠═6c40b89c-2bfe-11eb-3593-9d9ef6f45b80
# ╠═73c3869a-2bfd-11eb-0597-29cd6c1c90db
# ╠═a34f1e4c-2bfd-11eb-127e-295a7039c301
# ╠═c80e4362-2bfe-11eb-2055-5fbf167be551
# ╠═84880dfc-2bfd-11eb-32b7-47750e1c696b
# ╠═8c62855a-2bff-11eb-00f5-3702e142f76f
# ╠═ae8d6258-2bff-11eb-0182-afc33d9d4efc
# ╠═746d3578-2bff-11eb-121a-f3d17397a49e
# ╠═f41919a4-2bff-11eb-276f-a5edd5b374ac
# ╠═e1f23724-2bfd-11eb-1063-1d59909bcacc
# ╠═55bfb46a-2be5-11eb-2be6-1bc153db11ac
# ╠═04f3c460-2bed-11eb-1039-238bfb3ec445
# ╠═b3eed0e0-2bed-11eb-21d3-19323b600edf
# ╠═d523e4c6-301b-11eb-040a-f7a214cb785b
# ╠═fafc7e74-34c6-11eb-0ce1-8fe2e3215739
# ╠═0f7f9156-34c7-11eb-01dd-db5b3e1b0eca
# ╠═9c7ad77a-34c7-11eb-0636-5d4c8dd9542b
# ╠═24e09632-34ca-11eb-09c6-cd0a14601723
# ╠═ac4540e6-34ca-11eb-28a5-39a639f385a1
# ╠═1937de5a-34c8-11eb-0a99-afc09e510273
# ╠═47a40a70-34c8-11eb-2ae1-5fde1e1ef83c
# ╠═a35eda0c-34c8-11eb-27e4-35a06de2df43
# ╠═54e78bb0-34c8-11eb-0cf9-a1a2b398e107
