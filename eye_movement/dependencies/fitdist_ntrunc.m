function [norm_trunc, phat, phat_ci]  = fitdist_ntrunc(dat_normal, varargin)
% Alexey Ryabov. 
%2018/02/08  added the posibility to fit data truncted on the left, right and
%both sides
%2017/08/08
% Fitting the truncated Gaussian distribution
% [norm_trunc, phat, phat_ci]  = fitdist_ntrunc(dat_normal, Range)
% norm_trunc -- truncated Gaussian distribution
% phat -- the maximal likelyhood estimates for \mu and \sigma for this distribution 
% phat_ci -- confidence intervals for \mu and \sigma 
% dat_normal -- normally distributed data
% Range - if not defined then the min and max in dat_normal will be used
% Range verctor with two elements defining the range where the data is truncated
% for instance
% [norm_trunc, phat, phat_ci]  = fitdist_ntrunc(dat_normal, [2, 10])  %-- the data is truncated on both sides
% [norm_trunc, phat, phat_ci]  = fitdist_ntrunc(dat_normal, [2, Inf]) %-- the data is truncated on the left
% [norm_trunc, phat, phat_ci]  = fitdist_ntrunc(dat_normal, [-Inf, 10]) %-- the data is truncated on the right
% [norm_trunc, phat, phat_ci]  = fitdist_ntrunc(dat_normal, [-Inf, 10]) %-- the data is truncated on the right
% [norm_trunc, phat, phat_ci]  = fitdist_ntrunc(dat_normal, [NaN, 10]) %--
% the data is truncated on both sides,but the left border will be defined
% automatically as min(dat_normal)
% Example 
% mu1 = 3; sigma1 = 5;
% pd = makedist('Normal', 'mu', mu1,'sigma', sigma1);
% dat_normal = pd.random(10000, 1);
% %remove all values less than 1
% dat_normal = dat_normal(dat_normal>x_min);
% %fit the distribution
% [norm_trunc, phat, phat_ci] = fitdist_ntrunc(dat_normal);
% %Plot results
% figure(1)
% plot(x, (norm_trunc(x , phat(1), phat(2))))
if isempty(varargin)
    x_min = min(dat_normal);  
    x_max = max(dat_normal);
else
    min_max = varargin{1};
    if length(min_max) ~= 2
        error('The range should contain both min and max')
    end
    x_min = min_max(1);
    x_max = min_max(2);
    if isnan(x_min)
        x_min = min(dat_normal);  
    end
    if isnan(x_max)
        x_max = max(dat_normal);  
    end
end
ind = dat_normal >= x_min & dat_normal <= x_max;
if isempty(ind) || sum(ind) == 0
    error('The fitting range [ %g, %g] is empty', x_min, x_max);
else
    dat_normal = dat_normal(ind);
end
%The truncated pdf should be normilized. If we truncate from the left, then
%we divide by normcdf(-x_min, -mu, sigma) 
heaviside_l = @(x) 1.0*(x>=0); %define double Heaviside function, because in Matlab 2017 Heaviside returns sym instead of double
heaviside_r = @(x) 1.0*(x<=0); %Heaviside function, which equals zero on the right
if isinf(x_min)     %not truncated on left
    if isinf(x_max) %not truncated on left (a normal Gaussian)
        norm_trunc =@(x, mu, sigma) (normpdf(x , mu, sigma));
    else            %truncated on the right
        norm_trunc =@(x, mu, sigma) (normpdf(x , mu, sigma)./normcdf(x_max, mu, sigma) .* heaviside_r(x - x_max));
    end
else                %truncated on the left
    if isinf(x_max) %not truncated on the right
        norm_trunc =@(x, mu, sigma) (normpdf(x , mu, sigma)./normcdf(-x_min, -mu, sigma) .* heaviside_l(x - x_min));
    else            %truncated on the right (and left)
        normcdf_lr =@(mu, sigma) (normcdf(x_max, mu, sigma) - normcdf(x_min, mu, sigma));
        norm_trunc =@(x, mu, sigma) normpdf(x , mu, sigma)./normcdf_lr(mu, sigma) .* heaviside_l(x - x_min) .* heaviside_r(x - x_max);
    end
end
%find the maximum likelihood estimates using mean and std as an initial guess 
[phat, phat_ci]  = mle(dat_normal , 'pdf', norm_trunc,'start', [mean(dat_normal), std(dat_normal)]);