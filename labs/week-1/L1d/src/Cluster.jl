

function _cluster(data::Array{<:Number,2}, algorithm::MyNaiveKMeansClusteringAlgorithm; 
    d = Euclidean(), verbose::Bool = false)
    
    # get data -
    K = algorithm.K;
    ϵ = algorithm.ϵ;
    maxiter = algorithm.maxiter;
    assignments = algorithm.assignments;
    centroids = algorithm.centroids;
    dimension = algorithm.dimension;
    number_of_points = algorithm.number_of_points;
    loopcount = 1; # how many iterations have we done?\
    tmp = zeros(Float64, K);

    # main -
    has_converged = false; # convergence flag
    while (has_converged == false)
    
        # before we start, copy the old assignments and centroids -
        â = copy(assignments); # old assignments
        ĉ = copy(centroids); # old centroids
        
        # verbose mode -
        if (verbose == true) # dump the data to disk
            path_to_save_file = joinpath(pwd(), "tmp", "data-$(loopcount).jld2");
            save(path_to_save_file, Dict("assignments" => â, "centroids" => ĉ, "loopcount" => loopcount));
        end

        # update steps -
        # step 1: assign each data point to the nearest centriod -
        for i ∈ 1:number_of_points
            for k ∈ 1:K
                tmp[k] = d(data[i,:], centroids[k]);
            end
            assignments[i] = argmin(tmp);
        end
    
        # step 2: update the centroids -
        for k ∈ 1:K
            index_cluter_k = findall(x-> x == k, assignments); # index of the data vectors assigned to cluster k

            if (isempty(index_cluter_k) == true)
                continue;
            else
                for d ∈ 1:dimension
                    centroids[k][d] = mean(data[index_cluter_k, d]);
                end
            end
        end

        # check: have we reached the maximum number of iterations -or- have the centroids converged?
        if (loopcount > maxiter || d(â, assignments) ≤ ϵ)
            has_converged = true;
        else
            loopcount += 1; # update the loop count
        end
    end
    
    # return the model -
    return (assignments = algorithm.assignments, centroids = algorithm.centroids, loopcount = loopcount);
end

"""
    cluster(data::Array{<:Number,2}, algorithm::{<:MyAbstractUnsupervisedClusteringAlgorithm}; d = Euclidean(), verbose::Bool = false)


"""
function cluster(data::Array{<:Number,2}, algorithm::T; d = Euclidean(), verbose::Bool = false) where T <: MyAbstractUnsupervisedClusteringAlgorithm
    return _cluster(data, algorithm, d = d, verbose = verbose);
end

"""
    configurationenergy(data::Array{<:Number,2}, assignments::Array{Int64,1}, centroids::Dict{Int64, Vector{Float64}}; d = Euclidean())::Float64

The function computes the energy of the configuration of the data points given the assignments and the centroids.

### Arguments
- `data::Array{<:Number,2}`: A matrix of size `(N, D)` where `N` is the number of data points and `D` is the dimension of the data points.
- `assignments::Array{Int64,1}`: A vector of size `N` where each element is the cluster assignment of the corresponding data point.
- `centroids::Dict{Int64, Vector{Float64}}`: A dictionary where the keys are the cluster indices and the values are the centroids of the clusters.
- `d::MyAbstractDistanceMetric = Euclidean()`: A distance metric. Default is `Euclidean()`.

### Returns
- `Float64`: The energy of the configuration.
"""
function configurationenergy(data::Array{<:Number,2}, assignments::Array{Int64,1}, centroids::Dict{Int64, Vector{Float64}}; 
    d = Euclidean())::Float64
    
    # initialize -
    K = length(centroids); # number of clusters -
    energy = 0.0;
    
    # compute the energy -
    for k ∈ 1:K
        index_cluter_k = findall(x-> x == k, assignments); # index of the data vectors assigned to cluster k
        for i ∈ eachindex(index_cluter_k)
            j = index_cluter_k[i];
            energy += d(data[j,:], centroids[k])^2;
        end
    end
    
    # return the energy -
    return energy;
end