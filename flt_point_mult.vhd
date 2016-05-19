--single precision floating point multiplier
library ieee;
use ieee.std_logic_1164.all;

entity float_point_mult is
  port(A,B:in std_logic_vector(31 downto 0);
    P:out std_logic_vector(31 downto 0));
  end float_point_mult;
  
  architecture float_point_mult_arch of float_point_mult is
    
    component adder_8 is
      port(A,B:in std_logic_vector(7 downto 0);
          mode_sel:in std_logic;
          S:out std_logic_vector(7 downto 0));
      end component;
      
    component mult_24 is
      port(in1,in2:in std_logic_vector(23 downto 0);
          prod:out std_logic_vector(47 downto 0));
      end component;
        
    component shifter is
      port(inp:in std_logic_vector(47 downto 0);
        shift:in std_logic;
        outp:out std_logic_vector(47 downto 0));
      end component;
      
    component mux2in1_word is
      generic(n:integer);
      port(in1,in2:in std_logic_vector(n-1 downto 0);
         sel:in std_logic;
         mux_out:out std_logic_vector(n-1 downto 0));
     end component;
    
    signal prod_expo1,prod_expo_new,expo_final,incr_expo:std_logic_vector(7 downto 0);
    signal signif1,signif2,round_signif:std_logic_vector(23 downto 0);
    signal prod_signif,norm_signif:std_logic_vector(47 downto 0);
    signal tmp:std_logic_vector(31 downto 0);
    signal s1,s2,s3:std_logic;
    
    begin
      --calculating biased exponent of the product
      PE1:adder_8 port map(A(30 downto 23),B(30 downto 23),'0',prod_expo1);
      PE2:adder_8 port map(prod_expo1,"01111111",'1',prod_expo_new);
      --multiplying the significands
      signif1<='1'&A(22 downto 0);
      signif2<='1'&B(22 downto 0);
      SM1:mult_24 port map(signif1,signif2,prod_signif);
      --normalizing the significand
      NS1:shifter port map(prod_signif,prod_signif(47),norm_signif);
      NS2:adder_8 port map(prod_expo_new,"00000001",'0',incr_expo);
      NS4:mux2in1_word generic map(8)
                       port map(prod_expo_new,incr_expo, prod_signif(47),expo_final);
      --rounding the significand
      round_signif<=norm_signif(46 downto 23);
      --checking for overflow or underflow
      s1<=expo_final(0) and expo_final(1) and expo_final(2) and expo_final(3) and expo_final(4) and expo_final(5) and expo_final(6) and expo_final(7);
      s2<=(not expo_final(0)) and (not expo_final(1)) and (not expo_final(2)) and (not expo_final(3)) and (not expo_final(4)) and (not expo_final(5)) and (not expo_final(6)) and (not expo_final(7));
      s3<=s1 and s2;
      C1:mux2in1_word generic map(23)
                      port map(round_signif(22 downto 0),"00000000000000000000000",s3,tmp(22 downto 0));
      --defining the sign of the product
      tmp(31)<=A(31) xor B(31);
      tmp(30 downto 23)<=expo_final;--
      P<=tmp;                   
    end float_point_mult_arch; 
-------------------------------------------------
--8-bit adder/subtractor
library ieee;
use ieee.std_logic_1164.all;

entity adder_8 is
  port(A,B:in std_logic_vector(7 downto 0);
    mode_sel:in std_logic;
    S:out std_logic_vector(7 downto 0));
  end adder_8;
  
  architecture adder_8_arch of adder_8 is
    
    component full_adder is
      port(x,y,c_in:in std_logic;
        c_out,sum:out std_logic);
      end component;
      
    component xor_gate is
      port(in1,in2:in std_logic;
          xor_out:out std_logic);
      end component;
      
      signal buff,buff2:std_logic_vector(7 downto 0);
      
      begin
        X1:for j in 0 to 7 generate
          X:xor_gate port map(B(j),mode_sel,buff2(j));
          end generate X1;        
        L0:full_adder port map(A(0),buff2(0),mode_sel,buff(0),S(0));
        L1: for i in 1 to 7 generate
          L:full_adder port map(A(i),buff2(i),buff(i-1),buff(i),S(i));
          end generate L1;       
        end adder_8_arch; 
---------------------------------------------------------
--24-bit multiplier
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity mult_24 is
  port(in1,in2:in std_logic_vector(23 downto 0);
    prod:out std_logic_vector(47 downto 0));
  end mult_24;
  
  architecture mult_24_arch of mult_24 is
    begin
      prod<=in1*in2;
    end mult_24_arch;
--------------------------------------------------------
--shifter
library ieee;
use ieee.std_logic_1164.all;

entity shifter is
  port(inp:in std_logic_vector(47 downto 0);
    shift:in std_logic;
    outp:out std_logic_vector(47 downto 0));
  end shifter;
  
  architecture shift_arch of shifter is
    
    component mux2in1 is
      port(in1,in2,sel:in std_logic;
      mux_out:out std_logic);
    end component;
    
    begin
      Label1:mux2in1 port map(inp(47),'0',shift,outp(47));
      Label2:for i in 46 downto 0 generate
        Lbl:mux2in1 port map(inp(i),inp(i+1),shift,outp(i));
        end generate;
    end shift_arch;            
--------------------------------------------------------
--full adder
library ieee;
use ieee.std_logic_1164.all;

entity full_adder is
  port(x,y,c_in:in std_logic;
    c_out,sum:out std_logic);
  end full_adder; 
  
  architecture FA_arch of full_adder is
   begin
     sum <= x XOR y XOR c_in ;
     c_out <= (x AND y) OR (c_in AND x) OR (c_in AND y) ; 
  end FA_arch;
--------------------------------------------
--mux 2 in 1-word
library ieee;
use ieee.std_logic_1164.all;

entity mux2in1_word is
  generic(n:integer);
  port(in1,in2:in std_logic_vector(n-1 downto 0);
    sel:in std_logic;
    mux_out:out std_logic_vector(n-1 downto 0));
  end mux2in1_word;

architecture mux2in1_word_arch of mux2in1_word is
  
  component mux2in1 is
    port(in1,in2,sel:in std_logic;
      mux_out:out std_logic);
  end component;
  
  begin
   L: for i in 0 to n-1 generate
     SubL:mux2in1 port map(in1(i),in2(i),sel,mux_out(i));
     end generate;
   end mux2in1_word_arch;
--------------------------------------------
--mux 2 in 1-1 bit
library ieee;
use ieee.std_logic_1164.all;

entity mux2in1 is
  port(in1,in2,sel:in std_logic;
    mux_out:out std_logic);
  end mux2in1;
  
  architecture mux2in1_arch of mux2in1 is
    begin
        mux_out<=(in2 and sel) or (in1 and (not sel));
   end mux2in1_arch; 
--------------------------------------------
--xor gate
library ieee;
use ieee.std_logic_1164.all;

entity xor_gate is
  port(in1,in2:in std_logic;
    xor_out:out std_logic);
  end xor_gate;
  
  architecture xor_arch of xor_gate is
    begin
      xor_out<=in1 xor in2;
    end xor_arch;
------------------------------------------------
--testbench
library ieee;
use ieee.std_logic_1164.all;

entity test is
end test;

architecture test_beh of test is
  
  component float_point_mult is
    port(A,B:in std_logic_vector(31 downto 0);
      P:out std_logic_vector(31 downto 0));
  end component;
  
  signal A:std_logic_vector(31 downto 0):="00111111000000000000000000000000";
  signal B:std_logic_vector(31 downto 0):="10111110111000000000000000000000";
  signal P:std_logic_vector(31 downto 0);
  
  begin
    UUT: float_point_mult port map (A,B,P);
    end test_beh;