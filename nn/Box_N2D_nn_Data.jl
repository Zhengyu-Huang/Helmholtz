using Random, Distributions, NPZ
include("Box_Neumann_To_Dirichlet.jl")


function c_func_uniform(θ::Float64) 
    
    c = 50 + θ 
    
    return c
end



#=
Compute sorted pair (i, j), sorted by i^2 + j^2
wInt64h i≥0 and j≥0 and i+j>0

These pairs are used for Karhunen–Loève expansion
=#
function compute_seq_pairs(N_KL::Int64) 
    seq_pairs = zeros(Int64, N_KL, 2)
    trunc_Nx = trunc(Int64, sqrt(2*N_KL)) + 1
    
    seq_pairs = zeros(Int64, (trunc_Nx+1)^2 - 1, 2)
    seq_pairs_mag = zeros(Int64, (trunc_Nx+1)^2 - 1)
    
    seq_pairs_i = 0
    for i = 0:trunc_Nx
        for j = 0:trunc_Nx
            if (i == 0 && j ==0)
                continue
            end
            seq_pairs_i += 1
            seq_pairs[seq_pairs_i, :] .= i, j
            seq_pairs_mag[seq_pairs_i] = i^2 + j^2
        end
    end
    
    seq_pairs = seq_pairs[sortperm(seq_pairs_mag), :]
    return seq_pairs[1:N_KL, :]
end


#=
Generate parameters for logk field, based on Karhunen–Loève expansion.
They include eigenfunctions φ, eigenvalues λ and the reference parameters θ_ref, 
and reference field logk_2d field

logκ = ∑ u_l √λ_l φ_l(x)                l = (l₁,l₂) ∈ Z^{0+}×Z^{0+} \ (0,0)

where φ_{l}(x) = √2 cos(πl₁x₁)             l₂ = 0
                 √2 cos(πl₂x₂)             l₁ = 0
                 2  cos(πl₁x₁)cos(πl₂x₂) 
      λ_{l} = (π^2l^2 + τ^2)^{-d} 

They can be sorted, where the eigenvalues λ_{l} are in descending order

generate_θ_KL function generates the summation of the first N_KL terms 
=#
function c_func_random(x1::Float64, x2::Float64, θ::Array{Float64, 1}, seq_pairs::Array{Float64, 2}, d::Float64=2.0, τ::Float64=3.0) 
    
    N_KL = length(θ)
    
    a = 0
    
    for i = 1:N_KL
        λ = (pi^2*(seq_pairs[i, 1]^2 + seq_pairs[i, 2]^2) + τ^2)^(-d)
        
        if (seq_pairs[i, 1] == 0 && seq_pairs[i, 2] == 0)
            a += θ[i] * λ
        elseif (seq_pairs[i, 1] == 0)
            a += θ[i] * λ * sqrt(2)*cos.(pi * (seq_pairs[i, 2]*x2))
        elseif (seq_pairs[i, 2] == 0)
            a += θ[i] * λ * sqrt(2)*cos.(pi * (seq_pairs[i, 1]*x1))
        else
            a += θ[i] * λ * 2*cos.(pi * (seq_pairs[i, 1]*x1)) .*  cos.(pi * (seq_pairs[i, 2]*x2))
        end

        
    end
    
    c = 50 + exp(a)
    
    return c
end



function Data_Generate(generate_method::String, data_type::String, N_θ::Int64, N_per_θ::Int64; 
    ne::Int64 = 100,   seed::Int64=123)
    @assert(generate_method == "Uniform" || generate_method == "Random")
    @assert(data_type == "Direct" || generate_method == "Indirect")
    
    porder = 1
    Δx = 1.0/ne
    K_scale = zeros(Float64, ne*porder+1) .+ Δx
    K_scale[1] = K_scale[end] = Δx/2.0
    Random.seed!(seed)

    if generate_method == "Uniform" && data_type == "Direct"
        
        θ = rand(Uniform(0, 50), N_θ, 1);
        κ = zeros(ne+1, ne+1, N_θ)
        for i = 1:N_θ
            cs = [(x,y)->c_func_uniform(θ[i]);]
            # generate Dirichlet to Neumman results output for different condInt64ions
            # data =[nodal posInt64ions, (x, ∂u∂n, u), 4 edges, experiment number]
            data = Generate_Input_Output(cs, ne, porder);
            
            # data =[nodal posInt64ions, (x, ∂u∂n, u), 4 edges, experiment number]
            bc_id = 3
            u_n = data[:, 2, bc_id, :]
            u_d = data[:, 3, bc_id, :]
            K = u_d/u_n
            κ[:, :, i] = K ./ K_scale' 
        end 
        
        npzwrite("uniform_direct_theta.npy", θ)
        npzwrite("uniform_direct_K.npy", κ)
        
    else 
        @info "generate_method: $(generate_method) and data_type == $(data_type) have not implemented yet"
    end
    
    
    
end


Data_Generate("Uniform", "Direct", 100, 0; ne = 100,   seed = 123)