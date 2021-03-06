
import sys
import numpy as nmp

import barakuda_tool as brkdt

##########################################
# Expected name of variables in output nemo files #
##########################################

# grid_T file:
cv_temp = 'thetao'
cv_sali = 'so'
cv_sst  = 'tos'
cv_sss  = 'sos'
cv_ssh  = 'zos'
cv_mld  = 'mldr10_1'
#cv_mld  = 'mldkz5'

# grid_U file:
cv_u    = 'uo'
cv_taux = 'tauuo'

# grid_V file:
cv_v    = 'vo'
cv_tauy = 'tauvo'

# icemod file:
cv_icethickness = 'sit'
cv_ice_u = 'uice_ipa'  ; # Ice velocity along i-axis at I-point (ice presence average)
cv_ice_v = 'vice_ipa'  ; # Ice velocity along j-axis at I-point (ice presence average)
cv_ice_t = 'ist_ipa'   ; # Ice surface temperature (ice presence average)
cv_qnet_io = 'ioceflxb'; #Oceanic flux at the ice base


# AMOC file generated by CDFTOOLS:
cv_amoc = 'zomsfatl'


voce2treat = [ 'global', 'atlantic', 'pacific', 'indian' ]



# Definition of the boxes to zoom and average SSX on
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  => used into ssx_NAtl.py

cname_ssx_boxes = [  'NAtl'        , 'West_NAtl'   , 'GIN'      ]
clgnm_ssx_boxes = [  'N Atlantic'  , 'WN Atlantic' , 'GIN Seas' ]
r_lon_p1_ssx    = [   -85.         ,  -55.         ,  -22.      ]
r_lon_p2_ssx    = [    25.         ,  -20.         ,   25.      ]
r_lat_p1_ssx    = [    10.         ,   45.         ,   65.      ]
r_lat_p2_ssx    = [    72.         ,   64.         ,   73.      ]







# Definition of the boxes used to average MLD on
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  => used into mean.py and plot_time_series.py and compare_time_series.py...
cname_mld_boxes = [ 'Glob'  ,      'Sof40S'            ,      'Nof40N'           , 'NAtl'                   , '40S40N']
clgnm_mld_boxes = [ 'Global', r'South of 40$^{\circ}$S', 'North of 40$^{\circ}$N', 'Northern North Atlantic', '40$^{\circ}$S - 40$^{\circ}$N']

r_lon_p1_mld    = [   -999. ,     -999.                ,        -999.            ,  -75.                    ,     -999.    ]
r_lon_p2_mld    = [   -999. ,     -999.                ,        -999.            ,   15.                    ,     -999.    ]

r_lat_p1_mld    = [   -999. ,     -999.                ,         40.             ,   50.                    ,      -40.    ]
r_lat_p2_mld    = [   -999. ,      -40.                ,        -999.            ,   75.                    ,       40.    ]











# Simple 2D boxes :
# =================
boxes = [ [ 'nseas',  -60. , -40. , 40. , 70. ],
          [ 'med',  -17. , 0. , 30. , 42.     ],
          [ 'prout', -40. , -30. , 20. , 50.  ],
          [ 'prooo', -40. , -30. , 20. , 50.  ] ]               

 
# Coupes :
# ========        name      lon1  lon2  lat1  lat2  sal_min sal_max
coupes = [ [ 'med_vert',  -7.,      -7. ,  34., 37.         ],        
           [ 'ovide_60',  -43.,    -31.3,  60.6, 58.9       ],
           [ 'ovide_40',  -12.65, -8.7, 40.33, 40.33        ],            
           [ 'crap',      -12.,   -12., -20.,   80.         ],
           [ 'gibraltar', -8., -5.,  35.88, 35.88           ],     
           [ 'faroe-scot', -7.02869, -4.2513,  62.1826, 58.4656 ],
           [ 'atl_vert'  , -30., -30., -90., 90.          ]]







# For ORCA1 only:

# Old big Labrador box:
#vLabr =     [ 233,218 , 256,240 ]
#
# Smaller Lab box:
vLabr =     [ 236,222 , 252,235 ]
vIce_Scot = [ 255,225 , 282,243 ]
vGIN =      [ 266,245 , 290,271 ]
vNansenP1 = [ 272,276 , 294,291 ]
vNansenP2 = [  67,273 ,  89,289 ] # don't use the 2 upper points as they are already counted in vNansenP1
#                                 #(overlap of 2 points at the North ORCA cut)
#

vLabr_triangle = [ 241,222 , 252,227 , 236,234 ]

# Smaller inner boxes centered on convection patch for Labrador and GIN:
vLabr_s = [ 241,223 , 249,230 ]
vGIN_s  = [ 272,249 , 284,260 ]







def lon_reorg_orca(ZZ, corca, ilon_ext):
    #
    #
    # IN:
    # ===
    # ZZ       : array to  longitude, 3D, 2D field or 1D longitude vector
    # corca    : ORCA conf
    # ilon_ext : longitude extention in degrees
    #
    # OUT:
    # ====
    # ZZx     : re-organized array, the x dimension is now nx-2
    #
    #
    # jx_junc : ji when lon become positive!
    if corca == 'ORCA1' or corca == 'ORCA1.L64' or corca == 'ORCA1.L46':
        jx_junc = 288
    elif corca == 'ORCA025' or corca == 'ORCA025.L75':
        jx_junc = 1150
    elif corca == 'ORCA2' or corca == 'ORCA2_L46' or corca == 'ORCA2.L46':
        jx_junc = 141
    else:
        print 'ERROR: lon_reorg_orca.barakuda_orca => '+corca+' not supported yet!'; sys.exit(0)


    jx_oo = 2  # orca longitude overlap...
    #
    #
    vdim = ZZ.shape
    #
    ndim = len(vdim)
    #
    if ndim < 1 or ndim > 4:
        print 'util_orca.lon_reorg_orca: ERROR we only treat 1D, 2D, 3D or 4D arrays...'
        #
    #print vdim
    #
    #
    if ndim == 4:
        #
        [ nr, nz , ny , nx ] = vdim ;     nx0 = nx - jx_oo
        #print 'nx, ny, nz, nr = ', nx, ny, nz, nr
        #
        ZZx  = nmp.zeros(nx0*ny*nz*nr) ;  ZZx.shape = [nr, nz, ny, nx0]
        ZZx_ext  = nmp.zeros((nx0+ilon_ext)*ny*nz*nr) ;  ZZx_ext.shape = [nr, nz, ny, (nx0+ilon_ext)]
        #
        for jx in range(jx_junc,nx):
            ZZx[:,:,:,jx-jx_junc] = ZZ[:,:,:,jx]
        for jx in range(jx_oo,jx_junc):
            ZZx[:,:,:,jx+(nx-jx_junc)-jx_oo] = ZZ[:,:,:,jx]
        #
        if ilon_ext == 0: ZZx_ext[:,:,:,:] = ZZx[:,:,:,:]
    #
    #
    if ndim == 3:
        #
        [ nz , ny , nx ] = vdim ;     nx0 = nx - jx_oo
        #print 'nx, ny, nz = ', nx, ny, nz
        #
        ZZx  = nmp.zeros(nx0*ny*nz) ;  ZZx.shape = [nz, ny, nx0]
        ZZx_ext  = nmp.zeros((nx0+ilon_ext)*ny*nz) ;  ZZx_ext.shape = [nz, ny, (nx0+ilon_ext)]
        #
        for jx in range(jx_junc,nx):
            ZZx[:,:,jx-jx_junc] = ZZ[:,:,jx]
        for jx in range(jx_oo,jx_junc):
            ZZx[:,:,jx+(nx-jx_junc)-jx_oo] = ZZ[:,:,jx]
        #
        if ilon_ext == 0: ZZx_ext[:,:,:] = ZZx[:,:,:]
    #
    #
    if ndim == 2:
        #
        [ ny , nx ] = vdim ;     nx0 = nx - jx_oo
        #print 'nx, ny = ', nx, ny
        #
        ZZx  = nmp.zeros(nx0*ny) ;  ZZx.shape = [ny, nx0]
        ZZx_ext  = nmp.zeros((nx0+ilon_ext)*ny) ;  ZZx_ext.shape = [ny, (nx0+ilon_ext)]        
        #
        for jx in range(jx_junc,nx):
            ZZx[:,jx-jx_junc] = ZZ[:,jx]
        for jx in range(jx_oo,jx_junc):
            ZZx[:,jx+(nx-jx_junc)-jx_oo] = ZZ[:,jx]
        #
        if ilon_ext == 0: ZZx_ext[:,:] = ZZx[:,:]
    #
    #
    if ndim == 1:
        #
        [ nx ] = vdim ;     nx0 = nx - jx_oo
        #print 'nx = ', nx
        #
        ZZx  = nmp.zeros(nx0) ;  ZZx.shape = [nx0]
        ZZx_ext  = nmp.zeros(nx0+ilon_ext) ;  ZZx_ext.shape = [nx0+ilon_ext]
        #
        for jx in range(jx_junc,nx):
            ZZx[jx-jx_junc] = ZZ[jx]
            #print jx-jx_junc, 'prend', jx, '    ', vlon[jx]
            #
        #print ''
        for jx in range(jx_oo,jx_junc):
            ZZx[jx+(nx-jx_junc)-jx_oo] = ZZ[jx] 
            #print jx+(nx-jx_junc)-jx_oo, 'prend', jx, '    ', vlon[jx]
        #
        if ilon_ext == 0: ZZx_ext[:] = ZZx[:]
        #iwa = nmp.where(vlon0 < 0.) ; vlon0[iwa] = vlon0[iwa] + 360.
        #
        #
        #
        # Now longitude extenstion:
    if ilon_ext > 0: ZZx_ext = brkdt.extend_domain(ZZx, ilon_ext)
    #
    return ZZx_ext




def conf_run(ccr):
    #
    # Find the CONF from CONF-RUN and exit if CONF does not exist!
    #
    i = 0 ; conf = ''
    while i < len(ccr) and ccr[i] != '-' : conf = conf+ccr[i]; i=i+1
    #print 'conf =', conf, '\n'
    return conf


def info_run(ccr):
    #
    i = 0 ; j = 0 ; conf = '' ; case = '' ; cfrq = '' ; cyyy = ''
    #
    while i < len(ccr) and ccr[i] != '-' : conf = conf+ccr[i]; i=i+1
    i=i+1
    while i < len(ccr) and ccr[i] != '_' : case = case+ccr[i]; i=i+1
    i=i+1
    while i < len(ccr) and ccr[i] != '_' : cfrq = cfrq+ccr[i]; i=i+1
    i=i+1
    while i < len(ccr) and j < 4 : cyyy = cyyy+ccr[i]; i=i+1; j=j+1
    #
    return [conf, case, cfrq, cyyy]



def ind_coor(jpi, jpj, XX, XY):
    #
    # Return longitude and latitude of a point given as a jpi, jpj couple
    #
    lon = XX[jpj,jpi]
    lat = XY[jpj,jpi]
    #
    print 'Point jpi='+'%i' % jpi +', jpj='+'%i' % jpj+' has coordinates :', lon, lat
    #
    return [lon, lat]




def find_ij(lon, lat, XX, XY, char):
    #
    # char : 'c' for "closer"
    #        'u' for "under"
    #
    [nj,ni] = nmp.shape(XX)
    #
    # Temporary X array so we won't modify XX :
    Xt = nmp.zeros(nj*ni) ; Xt.shape = nmp.shape(XX)
    Xt[:,:] = XX[:,:]
    idm = nmp.where(XX < 0.)
    Xt[idm] = XX[idm] + 360.
    #
    E = nmp.zeros(nj*ni) ; E.shape = nmp.shape(XX)
    #
    tolx = 2. ; toly = 2.
    found = False

    lxfound = False
    lyfound = False    
    
    while not (lxfound and lyfound) :
      
        E[:,:] = 1.
        if not lxfound:
            E[nmp.where(Xt >= lon + tolx)] = 0.
            E[nmp.where(Xt <= lon - tolx)] = 0.
        if not lyfound:
            E[nmp.where(XY >= lat + toly)] = 0.
            E[nmp.where(XY <= lat - toly)] = 0.
      
        V = nmp.where(E == 1.) ; Vj = V[0] ; Vi = V[1]
      
        if len(Vi) == 1 or len(Vi) == 2:
            ji = Vi[0]
            if len(Vi) == 2 and abs(Vi[1]-lon) < abs(Vi[0]-lon): ji = Vi[1]
            lxfound = True
        else:
            tolx = tolx/1.05


        if len(Vj) == 1 or len(Vj) == 2:
            jj = Vj[0]
            if len(Vj) == 2 and abs(Vj[1]-lat) < abs(Vj[0]-lat): jj = Vj[1]
            lyfound = True            
        else:
            toly = toly/1.2

    
    ji0 = ji ; jj0 = jj
    
    if char == 'u':
        # We want the point such as the value is just under :
        if Xt[jj,ji] > lon : ji0 = ji - 1
        if XY[jj,ji] > lat : jj0 = jj - 1
    #
    return [ji0, jj0]




def pos_coor(vb, XX, XY):
    #_____________________________________________________________
    #
    # vb = [ lon1, lon2, lat1, lat2 ]
    #_____________________________________________________________
    #
    vp  = array([ 0, 0, 0, 0 ])
    #
    [nj,ni] = nmp.shape(XX)
    #
    if vb[0] < 0. :
        lx1 = vb[0] + 360.
    else:
        lx1 = vb[0]
    #
    if vb[1] < 0. :
        lx2 = vb[1] + 360.
    else:
        lx2 = vb[1]
    #
    ly1 =  vb[2] ; ly2 = vb[3]
    #
    print '0'
    [vp[0],vp[2]] = find_ij(lx1, ly1, XX, XY, 'c')
    print '1'
    [vp[1],vp[3]] = find_ij(lx2, ly2, XX, XY, 'c')
    print '2'
    #
    return vp



def int_trs(X, Y, Z, x0, y0):
    #
    max_itt = 8
    #
    #print 'shape(X)', shape(X) ; sys.exit(0)
    #
    [jpj,jpi] = nmp.shape(X)
    #
    # Finding ji, jj such as P0 = (x0,y0) belongs to mesh [ji,jj ji+1,jj ji+1,jj+1, ji,jj+1]
    #
    #
    cpt = 0
    ji0=1 ; ji_o=0
    jj0=1 ; jj_o=0
    #
    while jj0 != jj_o or ji0 != ji_o :
        #
        cpt = cpt + 1;
        if cpt == max_itt: break
        #
        for ji in range(jpi-1) :
            if x0 >= X[jj0,ji] and x0 < X[jj0,ji+1]:
                ji_o = ji0 ; ji0 = ji
                break
        #
        for jj in range(jpj-1) :
            if y0 >= Y[jj,ji0] and y0 < Y[jj+1,ji0]:
                jj_o = jj0; jj0 = jj;
                break
        #
        #print 'ji_o, jj_o, ji0, jj0', ji_o, jj_o, ji0, jj0
    #
    #print 'Took', cpt, 'itterations!\n'
    #
    if abs(Y[jj0,ji0] - y0) > 0.5 or abs(X[jj0,ji0] - x0) > 0.5:
        print 'Problem for lon0, lat0 = ', x0, y0
        print 'X[jj0,ji0], X[jj0,ji0+1] =', X[jj0,ji0], X[jj0,ji0+1]
        print 'Y[jj0,ji0], Y[jj0+1,ji0] =', Y[jj0,ji0], Y[jj0+1,ji0]
        print 'Took', cpt, 'itterations!\n \n'
        ji0=ji0-1 ; jj0=jj0-1
        print 'X[jj0,ji0], X[jj0,ji0+1] =', X[jj0,ji0], X[jj0,ji0+1]
        print 'Y[jj0,ji0], Y[jj0+1,ji0] =', Y[jj0,ji0], Y[jj0+1,ji0]
        #
        sys.exit(0)
        #
    #
    #eps = 1.e-8
    eps = 0.0
    #
    A1 = abs(x0 - X[jj0,ji0])    *abs(y0 - Y[jj0,ji0])     ; w1 = 1./(A1+eps)
    A2 = abs(X[jj0,ji0+1] - x0)  *abs(y0 - Y[jj0,ji0+1])   ; w2 = 1./(A2+eps)
    A3 = abs(X[jj0+1,ji0+1] - x0)*abs(Y[jj0+1,ji0+1] - y0) ; w3 = 1./(A3+eps)
    A4 = abs(x0 - X[jj0+1,ji0])  *abs(Y[jj0+1,ji0] - y0) ;   w4 = 1./(A4+eps)
    #
    #print 'w1 =', w1
    #print 'w2 =', w2
    #print 'w3 =', w3
    #print 'w4 =', w4    
    #
    #print 'shape(Z) = ', shape(Z)
    #
    val = w1*Z[jj0,ji0] + w2*Z[jj0,ji0+1] + w3*Z[jj0+1,ji0+1] + w4*Z[jj0+1,ji0]
    #
    val = val/(w1 + w2 + w3 + w4)
    #print 'val =', val
    #
    return val







def mean_3d(XD, LSM, E1T, E2T, E3T):
    #
    # XD             : 3D+T array containing data
    # LSM            : 3D land sea mask
    # E1T, E2T, E3T  : 3D mesh sizes
    #
    # RETURN vmean: vector containing mean values for each time
    
    [ lt, lz, ly, lx ] = nmp.shape(XD)


    [ l3, l2, l1     ] = nmp.shape(LSM)
    if [ l3, l2, l1 ] != [ lz, ly, lx ]:
        print 'ERROR: mean_3d.barakuda_orca.py => XD and LSM do not agree in shape!'
        sys.exit(0)
    [ l3, l2, l1     ] = nmp.shape(E1T)
    if [ l3, l2, l1 ] != [ lz, ly, lx ]:
        print 'ERROR: mean_3d.barakuda_orca.py => XD and E1T do not agree in shape!'
        sys.exit(0)
    [ l3, l2, l1     ] = nmp.shape(E2T)
    if [ l3, l2, l1 ] != [ lz, ly, lx ]:
        print 'ERROR: mean_3d.barakuda_orca.py => XD and E2T do not agree in shape!'
        sys.exit(0)
    [ l3, l2, l1     ] = nmp.shape(E3T)
    if [ l3, l2, l1 ] != [ lz, ly, lx ]:
        print 'ERROR: mean_3d.barakuda_orca.py => XD and E3T do not agree in shape!'
        sys.exit(0)

    vmean = []

    for jt in range(lt):
        zmean = nmp.sum( XD[jt,:,:,:]*LSM[:,:,:]*E1T[:,:,:]*E2T[:,:,:]*E3T[:,:,:] ) / nmp.sum( LSM[:,:,:]*E1T[:,:,:]*E2T[:,:,:]*E3T[:,:,:] )
        vmean.append(zmean)

    return vmean


def mean_2d(XD, LSM, E1T, E2T):
    #
    # XD        : 2D+T array containing data
    # LSM       : 2D land sea mask
    # E1T, E2T  : 2D mesh sizes
    #
    # RETURN vmean: the mean value at each record
    
    [ lt, ly, lx ] = nmp.shape(XD)

    [ l2, l1 ] = nmp.shape(LSM)
    if [ l2, l1 ] != [ ly, lx ]:
        print 'ERROR: mean_3d.barakuda_orca.py => XD and LSM do not agree in shape!'
        sys.exit(0)
    [ l2, l1 ] = nmp.shape(E1T)
    if [ l2, l1 ] != [ ly, lx ]:
        print 'ERROR: mean_3d.barakuda_orca.py => XD and E1T do not agree in shape!'
        sys.exit(0)
    [ l2, l1 ] = nmp.shape(E2T)
    if [ l2, l1 ] != [ ly, lx ]:
        print 'ERROR: mean_3d.barakuda_orca.py => XD and E2T do not agree in shape!'
        sys.exit(0)

    vmean = []

    for jt in range(lt):
        zmean = nmp.sum( XD[jt,:,:]*LSM[:,:]*E1T[:,:]*E2T[:,:] ) / nmp.sum( LSM[:,:]*E1T[:,:]*E2T[:,:] )
        vmean.append(zmean)

    return vmean












def coor2ind(cn_coupe, xlon, xlat): #, rmin, rmax, dc):
    #*******************************************
    #
    ji1=0 ; ji2=0; jj1=0; jj2=0
    lhori = False ; lvert = False
    dist = 10000.
    #
    vcoup = __give_coupe__(cn_coupe)
    if vcoup[0] < 0.: vcoup[0] = vcoup[0] + 360.
    if vcoup[1] < 0.: vcoup[1] = vcoup[1] + 360.
    #
    if vcoup[2] == vcoup[3]: lhori = True
    if vcoup[0] == vcoup[1]: lvert = True
    #
    if not (lhori or lvert) :
        print 'coor2ind only supports horizontal or vertical coupes so far...'
        sys.exit(0)
    #
    if lhori:
        print 'coor2ind horizontal mode not done yet'; sys.exit(0)
    #
    [nj , ni] = xlon.shape
    #
    iwa = nmp.where(xlon < 0.) ; xlon[iwa] = xlon[iwa] + 360. # Want only positive values in longitude:
    #
    #
    # Searching vor longitude position
    # ################################
    # Lookin in regular region of the grid (jj1 pas trop grand, ici = 0):
    for ji in range(ni):
        dd1 = abs(vcoup[0] - xlon[jj1,ji])
        if dd1 > 360.: dd1 = dd1 - 360.
        if dd1 < dist:
            dist = dd1 ; ji1 = ji
    ji2 = ji1
    if vcoup[2] == -90.: jj1 = 0
    if vcoup[3] ==  90.: jj2 = nj-1
    #
    return [ ji1, ji2, jj1, jj2 ]
    
    



def get_sections_names_from_file(cfile):
    list_sections = []
    f = open(cfile, 'r')
    cread_lines = f.readlines()
    f.close()
    jl=0
    for ll in cread_lines:
        ls = ll.split() ; cc = ls[0]
        if jl%2 == 0 and cc != 'EOF': list_sections.append(cc)
        jl=jl+1
    return list_sections







# Local functions:

def __give_coupe__(cname):
    #
    #
    nb = nmp.shape(coupes)[0] ; # print 'nb =', nb
    #
    jb = 0
    while jb < nb :
        if coupes[jb][0] == cname:
            break
        else :
            jb = jb + 1
    #
    if jb == nb :
        print 'COUPE "'+cname+'" does not exist!\n'
        print 'so far choice is :'
        for jb in range(nb): print coupes[jb][0]
        sys.exit(0)
        #
    #
    vcoupe = coupes[jb][1:]
    #
    print 'For ', coupes[jb][0], ' we have vcoupe =', vcoupe, '\n'
    #
    return vcoupe


def __give_box__(conf, cname):
    #
    #
    if conf == 'NATL12' :
        #
        nb = nmp.shape(boxes)[0]
        #
        jb = 0
        while jb < nb :
            if boxes[jb][0] == cname:
                break
            else :
                jb = jb + 1
        #
        if jb == nb :
            print 'Box "'+cname+'" does not exist!\n'
            print 'so far choice is :'
            for jb in range(nb): print boxes[jb][0]
            sys.exit(0)
        #
        vbox = boxes[jb][1:]
        #
        print 'For ', boxes[jb][0], ' we have vbox =', vbox, '\n'
        #
    return vbox


