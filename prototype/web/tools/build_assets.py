import json, base64, io, os, subprocess
from PIL import Image
# Ninja Adventure(CC0) 원본에서 쓰는 그림·소리만 골라 src/c3_na_data.js를 다시 만든다(결과 파일은 커밋돼 있어 보통은 실행할 필요 없음).
# 준비: Ninja Adventure - Asset Pack.zip을 assets/ninja-adventure/에 풀어 둔다. ffmpeg 필요.
import os as _os
_HERE = _os.path.dirname(_os.path.abspath(__file__)); _ROOT = _os.path.abspath(_os.path.join(_HERE, '..', '..', '..'))
_os.chdir(_os.path.join(_HERE, '..', 'out')) if _os.path.isdir(_os.path.join(_HERE, '..', 'out')) else (_os.makedirs(_os.path.join(_HERE, '..', 'out')), _os.chdir(_os.path.join(_HERE, '..', 'out')))
R=_os.path.join(_ROOT, 'assets', 'ninja-adventure', 'Ninja Adventure - Asset Pack') + '/'
T=R+'Backgrounds/Tilesets/'
sheets={'floor':T+'TilesetFloor.png','field':T+'TilesetField.png','nature':T+'TilesetNature.png','house':T+'TilesetHouse.png','elem':T+'TilesetElement.png'}
imgs={k:Image.open(v).convert('RGBA') for k,v in sheets.items()}
def tile(sheet,i):
    im=imgs[sheet]; cols=im.size[0]//16; x,y=i%cols,i//cols; return im.crop((x*16,y*16,x*16+16,y*16+16))
want={
 'grass':[('floor',264),('floor',264),('floor',264),('floor',265),('floor',266),('floor',264),('floor',267),('floor',264)],
 'path9':[('field',i) for i in [0,1,2,5,6,7,10,11,12]],
 'dirt9':[('field',i) for i in [45,46,47,50,51,52,55,56,57]],
 'tall':[('nature',271),('nature',271)],
 'flower':[('nature',264),('nature',267),('nature',270),('nature',266)],
 'treeA':[('nature',i) for i in [0,1,24,25]], 'treeB':[('nature',i) for i in [16,17,40,41]], 'treeC':[('nature',i) for i in [2,3,26,27]],
 'fence':[('house',142)], 'sign':[('elem',32)], 'well':[('elem',38)],
 'houseO':[('house',i) for i in [0,1,2,3,33,34,35,36,66,67,68,69]],
 'houseB':[('house',i) for i in [4,5,6,7,37,38,39,40,70,71,72,73]],
 'houseR':[('house',i) for i in [12,13,14,15,45,46,47,48,78,79,80,81]],
 'shelf':[('elem',i) for i in [120,121,136,137]],
 'jar':[('elem',1),('elem',4),('elem',3)], 'gourd':[('nature',225)], 'chest':[('elem',18),('elem',19)], 'stele':[('elem',36)],
 'treeO':[('nature',i) for i in [441,442,443,465,466,467,489,490,491]],
}
order=[]; meta={}
for k,lst in want.items():
    meta[k]=list(range(len(order),len(order)+len(lst))); order+=lst
cols=16; rows=(len(order)+cols-1)//cols
atlas=Image.new('RGBA',(cols*16,rows*16),(0,0,0,0))
for n,(s,i) in enumerate(order): atlas.paste(tile(s,i),((n%cols)*16,(n//cols)*16))
atlas.save('tiles.png')
# 캐릭터·몬스터 시트(4방향: 열 = 아래·위·왼·오, 행 = 걷기 프레임)
A=R+'Actor/'
chars={'me':'Character/Boy','reader1':'Character/Child','reader2':'Character/Woman','reader3':'Character/Villager3','keeper1':'Character/Master','shop':'Character/OldMan','kid':'Character/EggBoy',
 'p_haetae':'Character/LionYellow','p_heung':'Character/Villager','p_nolbu':'Character/Noble','e_servant':'Character/Caveman',
 'e_wisp':'Monster/Spirit','e_crow':'Monster/BlueBat','e_vine':'Monster/Bamboo',
 'n_nwife':'Character/Princess','n_rice':'Character/OldMan2','n_porter':'Character/Hunter','n_inn':'Character/Villager5','n_yeot':'Character/OldMan3','n_granny':'Character/OldWoman','n_girl':'Character/EggGirl',
 'p_zhangfei':'Character/Monk','p_guanyu':'Character/Sultan','p_liubei':'Character/Sultan2','p_zhuge':'Character/Inspector',
 'e_ytb':'Character/NinjaYellow','e_ytarch':'Character/FighterRed','e_ytbig':'Character/KnightGold','e_cyz':'Character/Samurai','e_zj':'Character/ShamanLion',
 't_spear':'Character/Knight','t_arch':'Character/NinjaGreen','t_shield':'Character/GladiatorBlue','t_rider':'Character/NinjaBlue'}
sp=[]; smeta={}; y=0
for k,p in chars.items():
    im=Image.open(A+p+'/SpriteSheet.png').convert('RGBA'); w,h=im.size; rows=min(4,h//16)
    im=im.crop((0,0,64,rows*16)); sp.append((im,y)); smeta[k]={'y':y,'rows':rows,'kind':'grid'}; y+=rows*16
par=Image.open(A+'Animal/Parrot/SpriteSheetBlue.png').convert('RGBA'); sp.append((par,y)); smeta['p_swallow']={'y':y,'rows':1,'kind':'strip','n':2,'w':16,'h':16}; y+=16
fox=Image.open(A+'Animal/CatOrange/SpriteSheet.png').convert('RGBA'); sp.append((fox,y)); smeta['p_gumiho']={'y':y,'rows':1,'kind':'strip','n':2,'w':fox.size[0]//2,'h':fox.size[1]}; y+=fox.size[1]
for key,f in [('a_horse','Animal/Horse/SpriteSheetBrown.png'),('a_horseB','Animal/Horse/SpriteSheetBlack.png'),('a_horseS','Animal/Horse/SpriteSheetBrownSide.png'),('a_horseBS','Animal/Horse/SpriteSheetBlackSide.png')]:
    hi=Image.open(A+f).convert('RGBA'); sp.append((hi,y)); smeta[key]={'y':y,'rows':1,'kind':'strip','n':2,'w':hi.size[0]//2,'h':hi.size[1]}; y+=hi.size[1]
dog=Image.open(A+'Animal/DogYellow/SpriteSheet.png').convert('RGBA'); sp.append((dog,y)); smeta['a_dog']={'y':y,'rows':1,'kind':'strip','n':2,'w':dog.size[0]//2,'h':dog.size[1]}; y+=dog.size[1]
boss=Image.open(A+'Boss/GiantSlime/Idle.png').convert('RGBA'); bw=boss.size[0]//5; sp.append((boss,y)); smeta['e_boss']={'y':y,'kind':'strip','n':5,'w':bw,'h':boss.size[1]}; y+=boss.size[1]
W=max(64,boss.size[0]); sheet=Image.new('RGBA',(W,y),(0,0,0,0))
for im,yy in sp: sheet.paste(im,(0,yy))
sheet.save('sprites.png')
# 소리(mp3, 모노)
S=R+'Audio/Sounds/'
sounds={'shoot':'Menu/Move2.wav','hit':'Hit & Impact/Hit1.wav','hurt':'Hit & Impact/Impact.wav','kill':'Bonus/Coin.wav','dash':'Jump & Bounce/Jump.wav','slam':'Hit & Impact/Impact3.wav','heal':'Magic & Skill/Heal.wav','alert':'Alert/Alert.wav','accept':'Menu/Accept.wav','win':'../Jingles/Success1.wav','lose':'../Jingles/GameOver.wav','step':'Menu/Move1.wav'}
music={'town':'../Musics/4 - Village.ogg','road':'../Musics/23 - Road.ogg','fight':'../Musics/17 - Fight.ogg'}
os.makedirs('aud',exist_ok=True); aud={}
for k,p in list(sounds.items())+list(music.items()):
    src=S+p; out='aud/'+k+'.mp3'; br='40k' if k in music else '48k'
    subprocess.run(['ffmpeg','-y','-loglevel','error','-i',src,'-ac','1','-ar','22050','-b:a',br,out],check=True)
    aud[k]=base64.b64encode(open(out,'rb').read()).decode()
b64=lambda f: base64.b64encode(open(f,'rb').read()).decode()
js='  // ═════════ Ninja Adventure (CC0, pixel-boy) 그림·소리 데이터 — 필요한 것만 골라 묶음 ═════════\n'
js+='  const NA = '+json.dumps({'tiles':'data:image/png;base64,'+b64('tiles.png'),'tmeta':meta,'sprites':'data:image/png;base64,'+b64('sprites.png'),'smeta':smeta,'aud':{k:'data:audio/mpeg;base64,'+v for k,v in aud.items()}},ensure_ascii=False)+';\n'
open(_os.path.join(_HERE, '..', 'src', 'c3_na_data.js'),'w',encoding='utf-8').write(js)
print('tiles',atlas.size,'sprites',sheet.size,'js KB',len(js)//1024, {k:len(v)//1024 for k,v in aud.items()})
