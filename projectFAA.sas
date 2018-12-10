/* importing excel files */
proc import datafile="/folders/myfolders/statcomp/faa1.xlsx" 
        out=statcomp.excelImport1 dbms=xlsx replace;
run;

proc import datafile="/folders/myfolders/statcomp/faa2.xlsx" 
        out=statcomp.excelImport2 dbms=xlsx replace;
run;

/* combining them and deleting data with blank lines */
data statcomp.faaCombinedBackup;
    set statcomp.excelImport1 statcomp.excelImport2;

    if no_pasg='.' & distance='.' then
        delete;
run;

/* DELETE 100 duplicate lines */
proc sort data=statComp.faaCombinedbackup nodupkey 
        out=statComp.faaCombinedStep1;
    by aircraft height pitch speed_ground distance;
run;

/* add a serial number  */
data statComp.faaCombinedStep1;
    set statcomp.faaCombinedStep1;
    serialNo=_N_;
run;

/* check for missing values  */
proc means data=statComp.faaCombinedStep1 nmiss;
run;

/* quality check of duration */
proc univariate data=statComp.faaCombinedStep1;
    var duration;
run;

/* DELETE 5 entries where duration is less than 40 minutes */
data statComp.faaCombinedStep2;
    set statComp.faacombinedstep1;

    if duration < 40 then
        if duration <> '.' then
            delete;
    run;

    proc sgplot data=StatComp.FaaCombinedStep2;
        histogram duration / scale=count;
        density duration;
        yaxis grid;
    run;

    /* quality check of passengers */
    proc univariate data=statComp.faaCombinedStep2;
        var no_pasg;
    run;

    proc sgplot data=StatComp.FaaCombinedStep2;
        histogram no_pasg / scale=count;
        density no_pasg;
        yaxis grid;
    run;

    /* quality check of speed_ground */
    proc univariate data=statComp.faaCombinedStep2;
        var speed_ground;
    run;

    proc sgplot data=StatComp.FaaCombinedStep2;
        scatter x=serialNo y=speed_ground /;
        xaxis max=945 display=(nolabel);
        yaxis grid;
    run;

    proc sgplot data=StatComp.FaaCombinedStep2;
        vbox speed_ground /;
        yaxis grid;
    run;

    /* quality check of speed_air */
    proc univariate data=statComp.faaCombinedStep2;
        var speed_air;
    run;

    proc sgplot data=StatComp.FaaCombinedStep2;
        scatter x=serialNo y=speed_air /;
        xaxis max=945 display=(nolabel);
        yaxis grid;
    run;

    proc sgplot data=StatComp.FaaCombinedStep2;
        vbox speed_air /;
        yaxis grid;
    run;

    /* comparing both speed variables  */
    data statComp.FaaCompareSpeeds;
        set statComp.FaacombinedStep2;

        if speed_air='.' then
            speed_air=0;
        keep serialNo speed_air speed_ground;
    run;

    proc sgplot data=StatComp.faaCompareSpeeds;
        scatter x=speed_ground y=speed_air /;
        xaxis grid;
        yaxis grid;
    run;

    /* quality check of height */
    proc univariate data=statComp.faaCombinedStep2;
        var height;
    run;

    proc sgplot data=StatComp.FaaCombinedStep2;
        histogram height /;
        yaxis grid;
    run;

    /* DELETE 5 negative height rows */
    data statComp.faaCombinedStep3;
        set statComp.faaCombinedStep2;

        if height < 0 then
            delete;
    run;

    /* quality check of pitch */
    proc univariate data=statComp.faaCombinedStep3;
        var pitch;
    run;

    proc sgplot data=StatComp.FaaCombinedStep3;
        histogram pitch /;
        density pitch;
    run;

    /* quality check of distance  */
    proc univariate data=statComp.faaCombinedStep3;
        var distance;
    run;

    proc sgplot data=StatComp.FaaCombinedStep3;
        vbox distance /;
        yaxis grid;
    run;

    proc sgplot data=StatComp.FaaCombinedStep3;
        histogram distance /;
        density distance;
    run;

    /*   NEXT STEP   */
    /* Dependancy test for aircraft */
    proc ttest data=statComp.FaaCombinedStep3;
        class aircraft;
        var distance;
    run;

    proc sgplot data=STATCOMP.FAACOMBINEDSTEP3;
        vbox distance / category=aircraft;
        yaxis grid;
    run;

    data statComp.faaCombinedBadDistance;
        set statComp.faaCombinedstep3;

        if distance > 200 & distance < 6000 then
            delete;
    run;

    proc print data=statComp.faaCombinedBadDistance;
    run;

    /* Dependancy test for duration */
    proc corr data=statComp.faaCombinedStep3;
        var duration;
        with distance;
    run;

    /* Dependancy test for number of passenger,height and pitch */
    proc corr data=statComp.faaCombinedStep3;
        var no_pasg height pitch;
        with distance;
    run;

    proc plot data=statComp.faaCombinedStep3;
        plot distance*no_pasg='N' distance*height='H' distance*pitch='P'/overlay;
        run;

        /* Dependency test for speed ground */
    proc corr data=statComp.faaCombinedStep3;
        var speed_ground;
        with distance;
    run;

    proc sgplot data=StatComp.FaaCombinedStep3;
        scatter x=speed_ground y=distance /;
        yaxis grid;
    run;

    proc sgplot data=StatComp.FaaCombinedStep3;
        reg x=speed_ground y=distance / lineattrs=(color=red thickness=2);
    run;

    /* Dependency test for speed air */
    proc corr data=statComp.faaCombinedStep3;
        var speed_air;
        with distance;
    run;

    proc sgplot data=StatComp.FaaCombinedStep3;
        scatter x=speed_air y=distance /;
        yaxis grid;
    run;

    proc sgplot data=StatComp.FaaCombinedStep3;
        reg x=speed_air y=distance / lineattrs=(color=red thickness=2);
    run;

    /* NEXT STEP     */
    /*  Create new speed_air variable   */
    proc corr data=statComp.faacombinedstep3;
        var speed_air;
        with speed_ground;
    run;

    proc reg data=statComp.faaCombinedStep3;
        model speed_air=speed_ground;
        run;

    proc univariate data=statComp.faaCombinedStep3;
        var speed_air;
    run;

    data statComp.FaaCombinedStep4;
        set statComp.FaaCombinedStep3;

        if speed_air='.' then
            speed_air=0.9758 * speed_ground + 2.5858;
    run;

    proc univariate data=statComp.faaCombinedStep4;
        var speed_air;
    run;

    /* Create flag  */
    data statComp.FaaCombinedStep5;
        set statComp.faaCombinedStep4;
        overrunYesNo='FALSE';

        if distance < 200 or distance > 6000 then
            overrunYesNo='TRUE';

        if speed_ground < 30 or speed_ground > 140 then
            overrunYesNo='TRUE';

        if speed_air < 30 or speed_air > 140 then
            overrunYesNo='TRUE';

        if height < 6 then
            overrunYesNo='TRUE';
    run;

    /*  NEXT STEP    */
    /* Modeling - Ba Dum Tass  */
    proc reg data=statComp.faaCombinedStep5;
        model distance=speed_ground speed_air;
        output out=statComp.faaResiduals r=residual;
        run;

    proc univariate data=statComp.faaResiduals normaltest;
        var residual;
        qqplot residual /Normal(mu=est sigma=est color=red l=1);
    run;

    /*   Including height and pitch   */
    proc reg data=statComp.faaCombinedStep5;
        model distance=speed_ground speed_air height pitch;
        output out=statComp.faaResiduals r=residual;
        run;

    proc univariate data=statComp.faaResiduals normaltest;
        var residual;
        qqplot residual /Normal(mu=est sigma=est color=red l=1);
    run;