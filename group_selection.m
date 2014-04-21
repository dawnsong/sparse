randn('state',23432);
rand('state',3454);

%% MAIN PROGRAM %%
d = datasets;
rf = reg_funcs;

% Get Data
[ I, R, totalassets, T ] = d.ftse100();
% [ I, R, totalassets, T ] = d.naive(200,1000);



%% MAIN CVX PROGRAM %%


% Calculating n groups with knn + kmeans
n = 8;
[index, groups] = knn(R, n);
combs = [];
size_combs = [];

logical_index = logical(zeros(n,totalassets));
for i=1:5
    logical_index(i,:) = logical(index==i)';
end

comb_idx = [];
group_idx = [];

% Creating indexes for combinations
for i = 1:n
    comb = combnk(1:n, i);    
    
    comb_rn = size(comb,1);
    comb_cn = size(comb,2);
    
    combs = [combs; [comb , zeros(comb_rn,n-comb_cn) ]];
    size_combs = [size_combs; ones(comb_rn,1)*i];
    
    for j=1:comb_rn
        tmp_comb_idx = logical(zeros(1,n));
        tmp_comb_idx(comb(j,:)) = true;
        
        tmp_group_idx = sum(logical_index(comb(j,:),:),1);
        
        comb_idx = [ comb_idx; tmp_comb_idx ];
        group_idx = [ group_idx; tmp_group_idx ];
    end
end


group_idx = logical(group_idx);
group_idx = group_idx(1:n,:);
% n=2;
% group_idx = group_idx(1:2,:);
% group_idx(2,:) = ~group_idx(1,:);

not_group_idx = ~group_idx;
group_sizes = sum(group_idx,2);
sqr_group_sizes = sqrt(group_sizes);

lambda = 10;

% % CVX to find optimal value for Lasso
% cvx_begin %quiet
%     variable pimat_gl(totalassets,n)
%     
%     minimize(square_pos(norm(I - sum(R'*pimat_gl,2))) + lambda*sum(sqr_group_sizes'*diag(norms(pimat_gl,2,1))) )
%     
%     subject to
% %         sum(pimat_l(:)) == 1
%         pimat_gl >= 0
%         pimat_gl(not_group_idx') == 0
% cvx_end
% 
% pimat_gl=pimat_gl/sum(pimat_gl(:));
% sum(pimat_gl,2)
% sum(pimat_gl,1)
% sum(abs(I-sum(R'*pimat_gl,2)))
% sum(sum(pimat_gl,2)<0.0001)



% %% Sparse Group Lasso
% 
% alpha = .3;
% 
% % CVX to find optimal value for Lasso
% cvx_begin %quiet
%     variable pimat_sgl(totalassets,n)
%     
%     minimize(square_pos(norm(I - sum(R'*pimat_sgl,2))) + (1-alpha)*lambda*sum(sqr_group_sizes'*diag(norms(pimat_sgl,2,1))) + alpha*lambda*sum(sum(abs(pimat_sgl))) )
%     
%     subject to
% %         sum(pimat_l(:)) == 1
%         pimat_sgl >= 0
%         pimat_sgl(not_group_idx') == 0
% cvx_end
% 
% pimat_sgl=pimat_sgl/sum(pimat_sgl(:));
% sum(pimat_sgl,2)
% sum(pimat_sgl,1)
% sum(abs(I-sum(R'*pimat_sgl,2)))
% sum(sum(pimat_sgl,2)<0.0001)




% Variables to keep track of results
totalcombinations = size(combs,1)

currRs = cell(1, totalcombinations);
pimats_n = cell(1, totalcombinations);
te_n = [];
all_size = [];


% Loop for all the possible combinations
for i = 1:totalcombinations
    i
    
    currR = [];
    
    % Generate our dataset for all possible combinations
    for j = 1:size_combs(i)
        currR = [currR; groups{combs(i,j)}];
    end
    
    curr_totalassets = size(currR,1);
    
    [ pimat_n, error ] = rf.abs(I,currR,T,curr_totalassets);
    
    
    % Calculating Tracking Error
    currRs{i} = currR;
    pimats_n{i} = pimat_n;
   
    te_n = [te_n; error];
    all_size = [ all_size; curr_totalassets ];
        
end

[srt_te srt_te_idx] = sort(te_n);
[ totalassets-all_size(srt_te_idx) srt_te ]

[srt_size srt_size_idx] = sort(all_size);
[ totalassets-srt_size te_n(srt_size_idx) ]

 xx = flip(totalassets-srt_size);
 yy = flip(te_n(srt_size_idx));
