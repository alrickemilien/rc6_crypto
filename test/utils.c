#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <inttypes.h>

size_t bin2hex (uint8_t *p, char hex[], size_t len)
{
  size_t  i;

  // Return 0 when length is 0
  if ((len & 1) != 0)
    return (0); 
  
  // For each 32bits value digits
  for (i=0; i < len; i++) {
    // Transform the two hex digits into 32bits value and stores into x
    sprintf(&hex[i * 2], "%2x", p[i]);
  } 

  return (len);
} 


size_t hex2bin (void *bin, const char hex[])
{
  size_t  len, i;
  int     x;
  uint8_t *p;
  
  p = (uint8_t*)bin;
  len = strlen (hex);
  
  // Return 0 when length is 0
  if ((len & 1) != 0)
    return (0); 
  
  // When one character of the string in not an hexa digit return 0
  for (i=0; i<len; i++) {
    if (isxdigit((int)hex[i]) == 0)
      return (0); 
  }
  
  // For each 2 digits
  for (i=0; i<len / 2; i++) {
    // Transform the two hex digits into 8bits value and stores into x
    sscanf (&hex[i * 2], "%2x", &x);
    p[i] = (uint8_t)x;
  } 

  return (len / 2);
} 