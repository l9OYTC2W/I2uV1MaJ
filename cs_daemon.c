#include <stdio.h>

int main(int argc, char **argv)
{
	int i;
	char mystr[1024]="/opt/local/matlab6p5/bin/matlab -nosplash";
	
	if (argc != 2 && argc!= 3)
	{
		fprintf(stderr,"Wrong number of arguments.\n");
		fprintf(stderr,"Syntax: cs_daemon mfile [display]\n\n");
		exit();
	}
	
	if (argc == 3)
	{
		strcat( mystr, " -display " );
		strcat( mystr, argv[2] );
	}
	
	strcat(mystr, " -r ");
	strcat(mystr, argv[1] );
	
	while (1==1)
	{
		system(mystr);
		sleep(3600);
	}
}