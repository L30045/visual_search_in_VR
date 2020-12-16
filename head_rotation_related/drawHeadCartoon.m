function [hout, hxbody, hybody] = drawHeadCartoon(x,y,angle,rin, handx, handy, event, shoulderAngle,doBody)
% drawHeadCartoon draw cartoon of a head with nose, and optionally hand and shoulders
%
% drawHeadCartoon(x,y,angle,[r]) %basic usage%
%
% [hout, hxbody, hybody] = drawHeadCartoon(x,y,angle,r, handx, handy, event, shoulderAngle,doBodyRelative)
%
% INPUT
%   x,y             head center
%   angle           head angle (nose pointing direction)
%   r               head radius (default .2)
%   handx, handy    hand position (optional)
%   event           event string
%   shoulderAngle   angle of shoulders
%   doBodyRelative  true keeps shoulders pointing forwards (for special plots)
%
% OUTPUT
%  hout             graphics handles of plotted features
%  hxbody, hybody   hand x,y in body-centered coordinates
%
% JRI  

if nargin==0
 eval(['help ' mfilename])
 return
end
% 

hout = [];
hxbody = nan;
hybody = nan;
if isnan(x), return, end

if nargin < 3
  angle = 0;
end

if nargin < 4
  rin = .2;
end

if nargin < 5
    handx=[];handy=[];
end
if nargin < 7
    event = {};
end
if nargin < 8
    shoulderAngle = [];
end

%if true, plot body relative, so shoulders are fixed pointing forwards
if nargin < 9
    doBody = false;
end

%convert to degrees
angle = angle*180/pi;
shoulderAngle = shoulderAngle*180/pi;

if doBody
    deltaAngle = shoulderAngle;
else
    deltaAngle = 0;
end

circ = linspace(0,2*pi,201);
rx = sin(circ) * rin + x;
ry = cos(circ) * rin + y;

rmax = rin;
base  = rmax-.0046;
basex = 0.3*rmax;                   % nose width
tip   = 1.4*rmax;
tiphw = .04*rmax;                    % nose tip half width
tipr  = .01*rmax;                    % nose tip rounding
nosex = [basex;tiphw;0;-tiphw;-basex] + x;
nosey = [base;tip-tipr;tip;tip-tipr;base] + y;

%draw
hold on

%directional quadrant--fill with very pale wedge
hw=[];
a=1;
if any(contains(event,'Reach/Forward'))
    xf = [0 -.6 .6 0];
    yf = [0 .6 .6 0];
    c = [.8 .8 1];
    hw=fill(xf+x, yf+y, c,'edgecolor','none','facealpha',1);
elseif any(contains(event,'Reach/Right'))
    xf = [0 .6 .6 0];
    yf = [0 .6 -.6 0];
    c = [.8 1 .8];
    hw=fill(xf+x, yf+y, c,'edgecolor','none','facealpha',1);
elseif any(contains(event,'Reach/Left'))
    xf = [0 -.6 -.6 0];
    yf = [0 -.6 .6 0];
    c = [1 .8 .8];
    hw=fill(xf+x, yf+y, c,'edgecolor','none','facealpha',1);
elseif any(contains(event,'Reach/Back'))
    xf = [0 -.6 .6 0];
    yf = [0 -.6 -.6 0];
    c = [.8 .8 .8];
    hw=fill(xf+x, yf+y, c,'edgecolor','none','facealpha',1);
end
if ~isempty(hw) && ~doBody && ~isempty(shoulderAngle)
    rotate(hw,[0,0,1],-shoulderAngle,[x,y,0])
end

%hand
h3=[];
h4=[];
if ~isempty(handx)
    if any(contains(event,'Hand/Proximity'))
        mc = [1 .5 0];
        ms = 8;
    elseif any(contains(event,'Hand/Wall'))
        mc = [1 0 0];
        ms = 8;
    else
       mc = [0 0 0]; 
       ms = 5;
    end
    h3=plot([x handx],[y handy],'k-');
    h4=plot(handx,handy,'ko','markerfacecolor',mc,'markersize',ms);
    if doBody
       rotate([h3 h4],[0,0,1],deltaAngle,[x,y,0]) %
    end
    hxbody = h4.XData;
    hybody = h4.YData;
end

%shoulder
h5=[];
if ~isempty(shoulderAngle)
    h5 = plot3([x-1.5*rin x+1.5*rin],[y y],[-.02 -.02],'k-','linewidth',3);
    rotate(h5,[0,0,1],-shoulderAngle + deltaAngle,[x,y,0])
end

%head
h1=fill(nosex,nosey,'g','edgecolor','k','linewidth',0.5);
rotate(h1,[0,0,1],-angle+deltaAngle,[x,y,0])

if any(contains(event,'Head/Proximity'))
    c = [1 .5 0];
elseif any(contains(event,'Head/Wall'))
    c = [1 0 0];
else
    c = 'w';
end
h2=fill([rx(:)' rx(1)], [ry(:)' ry(1)],c,'edgecolor','k','linewidth',1);
%axis equal

if nargout>=1
  hout = [h1 h2 h3 h4 h5 hw];
end

% ears
% q = .04; % ear lengthening
% q=0
% EarX  = [.497-.005  .510  .518  .5299 .5419  .54    .547   .532   .510   .489-.005] * rin*2; % rmax = 0.5
% EarY  = [q+.0555 q+.0775 q+.0783 q+.0746 q+.0555 -.0055 -.0932 -.1313 -.1384 -.1199 * rin];
% 
% plot(EarX,EarY)
% plot(-EarX, EarY)
