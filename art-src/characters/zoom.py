import sys
from PIL import Image
img=Image.open(sys.argv[1]).convert('RGBA')
fw,fh,row,col0,col1,scale=map(int,sys.argv[2:8])
crop=img.crop((col0*fw,row*fh,col1*fw,(row+1)*fh))
bg=Image.new('RGBA',crop.size,(70,86,120,255)); bg.alpha_composite(crop)
bg.resize((crop.width*scale,crop.height*scale),Image.NEAREST).convert('RGB').save(sys.argv[8])
