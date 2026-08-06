/* Synthetic generator for the public reproducibility workflow.
   It creates no real participant records and reads no restricted data. */

%macro generate_synthetic_data(
    out_data=SIMDATA.ANALYSIS_LONG,
    out_subjects=SIMDATA.SUBJECT_TRUTH,
    out_missing=SIMDATA.MISSING_TRUTH,
    out_summary=RESULTS.MISSING_SUMMARY,
    n_nci=4980,
    n_mci=3520,
    n_dem=1500,
    seed=25072026,
    missing_scenario=HUNT_MAR
);

    %local scenario;
    %let scenario=%upcase(&missing_scenario);

    %if &scenario ne COMPLETE and &scenario ne HUNT_MAR %then %do;
        %put ERROR: MISSING_SCENARIO must be COMPLETE or HUNT_MAR.;
        %return;
    %end;

    /* Group-specific random-intercept covariance matrices. */
    data &out_subjects;
        length DIAG $3;
        retain ID 0;
        if _N_=1 then call streaminit(&seed);

        do GroupIndex=1 to 3;
            select(GroupIndex);
                when(1) do;
                    DIAG='DEM'; N_Group=&n_dem;
                    d11=0.1716; d12=0.09555; d22=0.3097;
                    ResidualVariance_MOCA=0.2013;
                    ResidualVariance_PTAU217=0.1070;
                    MeanAge=83.64329627; SDAge=7.37773881;
                    ProbabilityMale=0.41214892;
                end;
                when(2) do;
                    DIAG='MCI'; N_Group=&n_mci;
                    d11=0.1988; d12=0.06981; d22=0.2443;
                    ResidualVariance_MOCA=0.1962;
                    ResidualVariance_PTAU217=0.07590;
                    MeanAge=77.69757026; SDAge=6.23426205;
                    ProbabilityMale=0.48873281;
                end;
                when(3) do;
                    DIAG='NCI'; N_Group=&n_nci;
                    d11=0.1963; d12=0.05728; d22=0.2424;
                    ResidualVariance_MOCA=0.2384;
                    ResidualVariance_PTAU217=0.05681;
                    MeanAge=76.37770172; SDAge=5.14431509;
                    ProbabilityMale=0.44700270;
                end;
                otherwise;
            end;

            L11=sqrt(d11);
            L21=d12/L11;
            L22=sqrt(d22-L21**2);

            do SubjectWithinGroup=1 to N_Group;
                ID+1;
                Z1=rand('normal'); Z2=rand('normal');
                B_MOCA=L11*Z1;
                B_PTAU217=L21*Z1+L22*Z2;
                AGE_H4=min(100,max(70,MeanAge+SDAge*rand('normal')));
                SEX_MALE=rand('bernoulli',ProbabilityMale);
                output;
            end;
        end;

        keep ID DIAG B_: d11 d12 d22 ResidualVariance_: AGE_H4 SEX_MALE;
    run;

    /* Long-format outcomes. MoCA has two occasions and p-tau217 has three. */
    data &out_data;
        if _N_=1 then call streaminit(%eval(&seed+1));
        set &out_subjects;
        length VAR $7;

        VAR='MOCA'; TrueRandomIntercept=B_MOCA;
        do TIME=0,1;
            select(DIAG);
                when('DEM') MeanTrue=ifn(TIME=0,3.9533,3.7977);
                when('MCI') MeanTrue=ifn(TIME=0,2.8472,2.9187);
                when('NCI') MeanTrue=ifn(TIME=0,2.0528,2.3242);
                otherwise MeanTrue=.;
            end;
            TrueResidualVariance=ResidualVariance_MOCA;
            RESP=MeanTrue+TrueRandomIntercept
                 +sqrt(TrueResidualVariance)*rand('normal');
            output;
        end;

        VAR='PTAU217'; TrueRandomIntercept=B_PTAU217;
        do TIME=-1,0,1;
            select(DIAG);
                when('DEM') do;
                    if TIME=-1 then MeanTrue=-0.8847;
                    else if TIME=0 then MeanTrue=-0.2926;
                    else MeanTrue=-0.1305;
                end;
                when('MCI') do;
                    if TIME=-1 then MeanTrue=-1.2111;
                    else if TIME=0 then MeanTrue=-0.7438;
                    else MeanTrue=-0.5592;
                end;
                when('NCI') do;
                    if TIME=-1 then MeanTrue=-1.2888;
                    else if TIME=0 then MeanTrue=-0.8750;
                    else MeanTrue=-0.6840;
                end;
                otherwise MeanTrue=.;
            end;
            TrueResidualVariance=ResidualVariance_PTAU217;
            RESP=MeanTrue+TrueRandomIntercept
                 +sqrt(TrueResidualVariance)*rand('normal');
            output;
        end;

        keep ID DIAG AGE_H4 SEX_MALE VAR TIME RESP MeanTrue
             TrueRandomIntercept TrueResidualVariance;
    run;

    proc sort data=&out_data; by ID VAR TIME; run;

    %if &scenario=HUNT_MAR %then %do;
        /* Obtain time-zero outcomes used by the calibrated MAR mechanism. */
        data work._baseline;
            set &out_data;
            by ID;
            retain SQRTMOCA_H4 LOGPTAU_H4;
            if first.ID then call missing(SQRTMOCA_H4,LOGPTAU_H4);
            if VAR='MOCA' and TIME=0 then SQRTMOCA_H4=RESP;
            else if VAR='PTAU217' and TIME=0 then LOGPTAU_H4=RESP;
            if last.ID then do;
                MOCA_H4_RAW=min(30,max(0,30-SQRTMOCA_H4**2));
                output;
            end;
            keep ID DIAG AGE_H4 SEX_MALE MOCA_H4_RAW LOGPTAU_H4;
        run;

        data &out_missing;
            if _N_=1 then call streaminit(%eval(&seed+3));
            set work._baseline;
            DEM=(DIAG='DEM'); MCI=(DIAG='MCI');

            eta=3.8204581764-0.4821933734*DEM-0.1560791159*MCI
                -0.0635681650*AGE_H4-0.0598286478*SEX_MALE
                +0.0722308531*MOCA_H4_RAW-0.2161436471*LOGPTAU_H4;
            if DIAG='DEM' then eta=eta-0.28513;
            else if DIAG='MCI' then eta=eta-0.07626;
            else eta=eta-0.02507;
            P_PARTICIPATION=logistic(eta);
            PARTICIPATED_AIT=rand('bernoulli',P_PARTICIPATION);

            if PARTICIPATED_AIT then do;
                eta=4.6828174257-0.3766831115*DEM-0.3031769808*MCI
                    -0.0423861907*AGE_H4+0.0559248521*SEX_MALE
                    +0.0284724736*MOCA_H4_RAW-0.1014627311*LOGPTAU_H4;
                if DIAG='DEM' then eta=eta-0.26707;
                else if DIAG='MCI' then eta=eta+0.05950;
                else eta=eta-0.09973;
                P_PTAU=logistic(eta);
                OBS_PTAU_AIT=rand('bernoulli',P_PTAU);

                eta=1.9850868053-0.6859834097*DEM-0.0664123980*MCI
                    -0.0557319122*AGE_H4+0.3901222341*SEX_MALE
                    +0.1798701539*MOCA_H4_RAW-0.4574327835*LOGPTAU_H4
                    +0.3933272986*OBS_PTAU_AIT;
                P_MOCA=logistic(eta);
                OBS_MOCA_AIT=rand('bernoulli',P_MOCA);
            end;
            else do;
                P_PTAU=0; P_MOCA=0;
                OBS_PTAU_AIT=0; OBS_MOCA_AIT=0;
            end;
            drop eta DEM MCI;
        run;

        data &out_data;
            merge &out_data(in=a)
                  &out_missing(keep=ID PARTICIPATED_AIT OBS_PTAU_AIT OBS_MOCA_AIT);
            by ID;
            if a;
            RESP_COMPLETE=RESP; OBSERVED=1;
            if TIME=1 and VAR='PTAU217' and not OBS_PTAU_AIT then do;
                RESP=.; OBSERVED=0;
            end;
            else if TIME=1 and VAR='MOCA' and not OBS_MOCA_AIT then do;
                RESP=.; OBSERVED=0;
            end;
        run;
        proc datasets library=work nolist; delete _baseline; quit;
    %end;
    %else %do;
        data &out_missing;
            set &out_subjects(keep=ID DIAG AGE_H4 SEX_MALE);
            PARTICIPATED_AIT=1; OBS_PTAU_AIT=1; OBS_MOCA_AIT=1;
            P_PARTICIPATION=1; P_PTAU=1; P_MOCA=1;
        run;
        data &out_data;
            set &out_data;
            RESP_COMPLETE=RESP; OBSERVED=1;
            PARTICIPATED_AIT=1; OBS_PTAU_AIT=1; OBS_MOCA_AIT=1;
        run;
    %end;

    proc sql;
        create table &out_summary as
        select DIAG, count(*) as N_Subjects,
               mean(PARTICIPATED_AIT) as Participation_Rate format=percent8.1,
               mean(OBS_PTAU_AIT) as pTau_AiT_Rate format=percent8.1,
               mean(OBS_MOCA_AIT) as MoCA_AiT_Rate format=percent8.1,
               mean(OBS_PTAU_AIT*OBS_MOCA_AIT) as Both_AiT_Rate format=percent8.1
        from &out_missing group by DIAG;
    quit;

    proc sort data=&out_data; by ID VAR TIME; run;
    proc sort data=&out_subjects; by DIAG ID; run;
    proc sort data=&out_missing; by DIAG ID; run;

%mend generate_synthetic_data;
