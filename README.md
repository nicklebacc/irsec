##### Linux blue team scripts

All non destructive, read/print only or auditing

Make sure to SS for IR



watch.sh: compares current state to baseline state

persist.sh: check for any persistence and prints it, remove after being warned. Can generate false positives though

user.sh: goes through users and prints ones who show risk, audit only

common.sh: common file references regarding information needed. sets right box information 

baseline.sh : gets snapshot of beginning box, to run only @ beginning

