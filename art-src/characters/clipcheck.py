import sys
import numpy as np
from PIL import Image
img=np.array(Image.open(sys.argv[1])); fw,fh=int(sys.argv[2]),int(sys.argv[3])
for r in range(img.shape[0]//fh):
    for c in range(img.shape[1]//fw):
        f=img[r*fh:(r+1)*fh,c*fw:(c+1)*fw,3]>0
        if not f.any(): continue
        ys,xs=np.where(f)
        flag=[]
        if xs.min()==0: flag.append('L')
        if xs.max()==fw-1: flag.append('R')
        if ys.min()==0: flag.append('T')
        if flag: print(sys.argv[1],'row',r,'col',c,flag,'x',xs.min(),xs.max(),'y',ys.min(),ys.max())
