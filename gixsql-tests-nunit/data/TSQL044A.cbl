       IDENTIFICATION DIVISION.

       PROGRAM-ID. TSQL044A.

       ENVIRONMENT DIVISION.

       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-AT.
       OBJECT-COMPUTER. IBM-AT.

       DATA DIVISION.

       WORKING-STORAGE SECTION.

           01 DATASRC PIC X(64).
           01 DBUSR  PIC X(64).

           01 ENO-V    PIC S9(4) COMP.
           01 LNAME-V  PIC X(10).
           01 ROWS-READ PIC 9(4) VALUE 0.

       EXEC SQL
            INCLUDE SQLCA
       END-EXEC.

           EXEC SQL
               DECLARE CRS044 CURSOR FOR
               SELECT ENO, LNAME FROM EMPTABLE ORDER BY ENO
           END-EXEC.

       PROCEDURE DIVISION.

       000-CONNECT.

           DISPLAY "DATASRC" UPON ENVIRONMENT-NAME.
           ACCEPT DATASRC FROM ENVIRONMENT-VALUE.
           DISPLAY "DATASRC_USR" UPON ENVIRONMENT-NAME.
           ACCEPT DBUSR FROM ENVIRONMENT-VALUE.

           EXEC SQL
              CONNECT TO :DATASRC USER :DBUSR
           END-EXEC.

           DISPLAY 'CONNECT SQLCODE: ' SQLCODE.
           IF SQLCODE <> 0 THEN
              GO TO 100-EXIT
           END-IF.

       100-MAIN.

           EXEC SQL OPEN CRS044 END-EXEC.
           DISPLAY 'OPEN SQLCODE   : ' SQLCODE.

      * 200-FETCH-ROW is deliberately the LAST paragraph of the
      * program and is reached through PERFORM, not fall-through.
           PERFORM 200-FETCH-ROW.
           PERFORM UNTIL SQLCODE <> 0
              PERFORM 200-FETCH-ROW
           END-PERFORM.

           EXEC SQL CLOSE CRS044 END-EXEC.
           DISPLAY 'ROWS READ: ' ROWS-READ.

           EXEC SQL CONNECT RESET END-EXEC.

       100-EXIT.
           DISPLAY 'DONE'.
           STOP RUN.

       200-FETCH-ROW.
           EXEC SQL
              FETCH CRS044 INTO :ENO-V, :LNAME-V
           END-EXEC.
           IF SQLCODE = 0 THEN
              ADD 1 TO ROWS-READ
              DISPLAY 'ROW ' ENO-V ' ' LNAME-V
           END-IF.
