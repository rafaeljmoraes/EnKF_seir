module m_readinputs
logical lrtime    ! Continuous R(t) 
real rdcorr       ! decorrelation time for R(t)
real qminf        ! If set to 0.0 < qminf <= 1.0 then qminf fraction of Qm contributes to spreading virus
real hos          ! The fraction of fatally ill that actually goes to the hospital.
logical lRrescale ! Rescales the Rmatrix_0? such that the effective R(t) is not dependent on Rmatrix

contains
subroutine readinputs()
   use mod_dimensions
   use mod_params
   use mod_parameters 
   use m_enkfini 
   use m_getday
   implicit none
   logical ex
   character(len=2) ca
   integer id,im,iy,k,day
   integer ir,i,j,ii
   real stdR(nrint),fgR(nrint),dt,t

   inquire(file='infile.in',exist=ex)
   if (.not.ex) then
      print '(a)','Did not find inputfile infile.in...'
      stop
   endif
   open(10,file='infile.in')
      read(10,*)nrens               ;    print '(a,i4)',       'number  of samples         :',nrens
      read(10,*)nt                  ;    print '(a,i4)',       'nt                         :',nt
      read(10,*)time                ;    print '(a,f10.3)',    'Length of integration      :',time
      read(10,'(a)')ca      
      if (ca /= '#1') then
         print *,'#1: error in infile.in'
         stop
      endif
      read(10,*)lenkf               ;    print '(a,l1)',       'Run enkf update            :',lenkf
      read(10,*)mode_analysis       ;    print '(a,i2)',       'Analysis mode of EnKF      :',mode_analysis
      read(10,*)nesmda              ;    print '(a,i2)',       'Number of ESMDA steps      :',nesmda
      read(10,*)ld, relerrd, minerrd, maxerrd 
               print '(a,l1,3f10.2)','D conditioning, relerr, minerr, maxerr        :',ld, relerrd, minerrd, maxerrd
      read(10,*)lh, relerrh, minerrh, maxerrh 
               print '(a,l1,3f10.2)','H conditioning, relerr, minerr, maxerr        :',lh, relerrh, minerrh, maxerrh
      read(10,*)lc, relerrc, minerrc, maxerrc , cfrac
               print '(a,l1,4f10.2)','C conditioning, relerr, minerr, maxerr, cfrac :',ld, relerrd, minerrd, maxerrd, cfrac
      read(10,*)lmeascorr           ;    print '(a,l1)',       'Activate corr. obs. err.   :',lmeascorr
      read(10,*)rh                  ;    print '(a,f10.4)',    'Obs error decorrelation    :',rh
      read(10,*)truncation          ;    print '(a,f10.4)',    'EnKF SVD truncation (0.99) :',truncation

      read(10,'(a)')ca      
      if (ca /= '#2') then
         print *,'#2: error in infile.in'
         stop
      endif

! Read startday of simulation - Running with Rmat(:,:,1)
      read(10,'(tr1,i2,tr1,i2,tr1,i4)')id,im,iy
      startday=getday(id,im,iy)
      print '(a,i3,i3,i5,i5)',       'Start date of simulation        :',id,im,iy
      print '(a,2i5)',               'Relative start day              :',startday,365+31+28+1



! Read startday of 1st intervention - switching to Rmat(:,:,2)
      read(10,'(tr1,i2,tr1,i2,tr1,i4)')id,im,iy
      Tinterv(1)=real(getday(id,im,iy))
      print '(a,i3,i3,i5,f10.2,i5)',    'Start date of first  intervention:',id,im,iy,Tinterv(1)

! Read startdate of 2nd intervention- switching to Rmat(:,:,3)
      read(10,'(tr1,i2,tr1,i2,tr1,i4)')id,im,iy
      Tinterv(2)=real(getday(id,im,iy))
      print '(a,i3,i3,i5,f10.2,i5)',    'Start date of second intervention:',id,im,iy,Tinterv(2)


      read(10,'(a)')ca      
      if (ca /= '#3') then
         print *,'#3: error in infile.in'
         stop
      endif

! MODEL PARAMETERS (Set first guess (ensemble mean) of parameters (decleared in mod_parameters.F90) and their stddev 
      read(10,*)lRrescale            ; print '(a,tr9,l1,f10.3)','Rescaling of Rmatrix_0?              :',lRrescale
      read(10,*)lrtime , rdcorr      ; print '(a,tr9,l1,f10.3)','R(t) (TF) and decorrelation legnth   :',lrtime   ,rdcorr
      read(10,*)fgR(1) , stdR(1)     ; print '(a,2f10.3)',  'prior R until 1st interv and std dev :',fgR(1)   ,stdR(1)
      read(10,*)fgR(2) , stdR(2)     ; print '(a,2f10.3)',  'prior R 1st-2nd interv   and std dev :',fgR(2)   ,stdR(2)
      read(10,*)fgR(3) , stdR(3)     ; print '(a,2f10.3)',  'prior R 2nd-3rd interv   and std dev :',fgR(3)   ,stdR(3)
      read(10,*)p%E0   , parstd%E0   ; print '(a,2f10.3)',  'Initial exposed E0       and std dev :',p%E0     ,parstd%E0
      read(10,*)p%I0   , parstd%I0   ; print '(a,2f10.3)',  'Initial infected I0      and std dev :',p%I0     ,parstd%I0
      read(10,*)p%Tinc , parstd%Tinc ; print '(a,2f10.3)',  'Incubation time          and std dev :',p%Tinc   ,parstd%Tinc
      read(10,*)p%Tinf , parstd%Tinf ; print '(a,2f10.3)',  'Infection time           and std dev :',p%Tinf   ,parstd%Tinf
      read(10,*)p%Trecm, parstd%Trecm; print '(a,2f10.3)',  'Recovery time mild       and std dev :',p%Trecm  ,parstd%Trecm
      read(10,*)p%Trecs, parstd%Trecs; print '(a,2f10.3)',  'Recovery time severe     and std dev :',p%Trecs  ,parstd%Trecs
      read(10,*)p%Thosp, parstd%Thosp; print '(a,2f10.3)',  'Hospitalization time     and std dev :',p%Thosp  ,parstd%Thosp
      read(10,*)p%Tdead, parstd%Tdead; print '(a,2f10.3)',  'Time to death            and std dev :',p%Tdead  ,parstd%Tdead
      read(10,*)p%CFR  , parstd%CFR  ; print '(a,2f10.3)',  'Critical fatality ratio  and std dev :',p%CFR    ,parstd%CFR
      read(10,*)p%p_sev, parstd%p_sev; print '(a,2f10.3)',  'Fraction of severe cases and std dev :',p%p_sev  ,parstd%p_sev

! Some other model parameter that are not estimated
      read(10,*)hos                  ; print '(a,2f10.3)',  'Fraction of Qf that go to hospital   :',hos
      read(10,*)qminf                ; print '(a,2f10.3)',  'Fraction of Qm that is infecteous    :',qminf

      do i=0,min(nt,rdim)
         dt= time/real(nt-1)
         t= 0 + real(i)*dt
         if (t <= Tinterv(1)) then
            ir=1
         elseif (Tinterv(1) < t .and. t <= Tinterv(2) ) then
            ir=2
         elseif (t > Tinterv(2)) then
            ir=3
         endif
         p%R(i)=fgR(ir)     
         parstd%R(i) = stdR(ir) 
      enddo

      pfg=p          ! store first guess of parameters

      read(10,'(a)')ca      
      if (ca /= '#4') then
         print *,'#4: error in infile.in'
         stop
      endif

      read(10,*)minpar              ;    print '(a,f10.3)',    'Lower bound on all paramters         :',minpar
      read(10,*)rtmax               ;    print '(a,f10.3)',    'Maximum value of Rt during intervent :',rtmax

      read(10,'(a)')ca      
      if (ca /= '#5') then
         print *,'#5: error in infile.in'
         stop
      endif

   close(10)


   inquire(file='R.in',exist=ex)
   if (ex) then
      print '(a)','Reading prior R and standard deviation from R.in'
      open(10,file='R.in')
         do i=0,min(nt,rdim)
            read(10,*,end=200)ii,p%R(i),parstd%R(i)
         enddo
         200 close(10)
         if (i < min(nt,rdim)) then
            do j=i,min(nt,rdim)
               p%R(j)=p%R(i)
               parstd%R(j)=parstd%R(i)
            enddo
         endif
   endif
      print '(a)','Writing prior R and standard deviation to R.template'
      open(10,file='R.template')
         do i=0,min(nt,rdim)
            write(10,'(i6,2f13.3)')i,p%R(i),parstd%R(i)
         enddo
      close(10)
end subroutine
end module

