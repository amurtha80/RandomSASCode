proc fcmp outlib=sasuser.funcs.strings;

      function strmatch(a $, b $);
            la = upcase(trim(a));
            lb = upcase(trim(b));
            if la = lb then return(100);

            /*if substr(la,1,length(la)) = substr(lb,1,length(lb)) then return (100);*/
            score1 = compged(la,lb) / min(length(la), length(lb));
            score2 = compged(lb,la) / min(length(la), length(lb));
            score = (score1+score2) / 2;
            score = min(score,100);
            score = 100 - round(score, 1);
            return (score);
   endsub;
options cmplib=sasuser.funcs;
run;




data _null_;
      score = strmatch('John Q. Smith', 'J. Q. Smerth');
      put score=;
run;
