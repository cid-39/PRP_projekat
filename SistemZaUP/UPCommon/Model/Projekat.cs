using System;
using System.Collections.Generic;
using System.Text;

namespace UPCommon.Model
{
    public class Projekat
    {
        public long Id { get; set; } 
        public string Naziv { get; set; }
        public DateTime DatumPocetka { get; set; } 
        public DateTime? DatumZavrsetka { get; set; }
        public string StatusProj { get; set; } 
    }
}