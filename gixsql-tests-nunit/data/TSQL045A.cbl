       IDENTIFICATION DIVISION.

       PROGRAM-ID. TSQL045A.

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
           01 ZERO-V   PIC 9(4) VALUE 7.
           01 TOTAL-V  PIC 9(4) VALUE 0.
           01 ROWS-READ PIC 9(4) VALUE 0.

       EXEC SQL
            INCLUDE SQLCA
       END-EXEC.

           EXEC SQL
               DECLARE CRS045 CURSOR FOR
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

      * Host variables below have NO null indicator.
           EXEC SQL
              SELECT ENO, LNAME INTO :ENO-V, :LNAME-V
                FROM EMPTABLE WHERE ENO = 456
           END-EXEC.
           DISPLAY 'SELECT SQLCODE : ' SQLCODE.
           DISPLAY 'SELECT ROW     : ' ENO-V ' ' LNAME-V.

           EXEC SQL OPEN CRS045 END-EXEC.

           PERFORM UNTIL SQLCODE <> 0
              EXEC SQL
                 FETCH CRS045 INTO :ENO-V, :LNAME-V
              END-EXEC
              IF SQLCODE = 0 THEN
                 ADD 1 TO ROWS-READ
              END-IF
           END-PERFORM.
           DISPLAY 'FETCH END CODE : ' SQLCODE.

           EXEC SQL CLOSE CRS045 END-EXEC.

      * The fetches must not have overwritten the shared literal 0.
           MOVE 0 TO ZERO-V.
           ADD 0 TO TOTAL-V.
           DISPLAY 'LITERAL ZERO   : ' 0.
           DISPLAY 'ZERO-V         : ' ZERO-V.
           DISPLAY 'TOTAL-V        : ' TOTAL-V.
           DISPLAY 'ROWS READ      : ' ROWS-READ.

           EXEC SQL CONNECT RESET END-EXEC.

       100-EXIT.
           STOP RUN.
