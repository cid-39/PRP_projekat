using System;
using System.Collections.Generic;
using System.Text;

namespace UPCommon.Model
{
    public class Zadatak
    {
        public long Id { get; set; }
        public string Opis { get; set; }
        public DateTime DatumRoka { get; set; }
        public string StatusZad { get; set; }
        public int Prioritet { get; set; }
        public long IdProjekta { get; set; }
    }
}
