#-------------------------------------------------------------------------------
# Name:        Datasorter
# Purpose:     Find clusters in taxonomic data
#
# Author:      Juhani Hopkins
#
# Created:     16/04/2014
# Copyright:   (c) Juhani Hopkins 2014
# Licence:     GPL
#-------------------------------------------------------------------------------

# Input code to get the file with the data and the relevant information about it
# into the program.
print("The program does not check for input errors, so be careful.")
filename = input("Give the name of the file (e.g. 'data.txt'" )
delimiter = ";"# input("What is the delimiter in the file? ")
print("Give columns as letters")
startcolumn = ord(input("What column does your data start at? ").upper()) - 65
#number_of_cols = input("How many columns include data? ") #Feature not implemented yet
print("currently only works with four columns, for less than that, copy-paste the final column, for more, do them in batches")

# This section takes the file, opens it and splits the data in columns according
# to the method used to identify species.
file = open(filename, "r")
columna = []
columnb = []
columnc = []
columnd = []

for line in file:
    columna.append(line.split(delimiter)[startcolumn])
    columnb.append(line.split(delimiter)[startcolumn + 1])
    columnc.append(line.split(delimiter)[startcolumn + 2])
    columnd.append(line.split(delimiter)[startcolumn + 3])

'''
The main part of the code. It checks the starting and ending position of each
species in each method. Each species then gets given a value similar to 1:5.
Meaning that the first time the species was encoutered was on line 1 and the
last time was on line 4.
The same thing is repeated for each column. The first species in each column may
be left out, so the user should check it manually.
'''
A = []
B = []
C = []
D = []

count = 0

for a in columna:
    count = count + 1
    if count != len(columna):
        if a != columna[count]:
            A.append(count)
methodA = []
count = 0
for a in A[:-1]:
    count = count + 1
    methodA.append(str(a) + ":" + str(A[count]))


count = 0

for a in columnb:
    count = count + 1
    if count != len(columnb):
        if a != columnb[count]:
            B.append(count)
methodB = []
count = 0
for a in B[:-1]:
    count = count + 1
    methodB.append(str(a) + ":" + str(B[count]))

count = 0

for a in columnc:
    count = count + 1
    if count != len(columnc):
        if a != columnc[count]:
            C.append(count)
methodC = []
count = 0
for a in C[:-1]:
    count = count + 1
    methodC.append(str(a) + ":" + str(C[count]))

count = 0

for a in columnd:
    count = count + 1
    if count != len(columnd):
        if a != columnd[count]:
            D.append(count)
methodD = []
count = 0
for a in D[:-1]:
    count = count + 1
    methodD.append(str(a) + ":" + str(D[count]))
'''
The final part of the code checks which sets of number (e.g. 1:5) are the same
in all four methods and saves them as 'common'. It then checks method A to get
names for these species and saves them to the file 'results.txt'.
'''
common = set(methodA) & set(methodB) & set(methodC) & set(methodD)

common = sorted(common)
listnames = []
for a in common:
    ident = int(a.split(":")[0])
    name = columna[ident]
    listnames.append(name)

listnames = sorted(listnames)
file = open("results.txt", "w")
for name in listnames:
    file.write(name + "\n")

file.close()





