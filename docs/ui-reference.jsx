import { useState } from "react";

// ─── Palette & Design Tokens ────────────────────────────────
const T = {
  terracotta: "#C2553A",
  terracottaHover: "#A8432D",
  terracottaLight: "#E8A87C",
  terracottaPale: "#F5DCC8",
  dark: "#2A1D17",
  darkOverlay: "rgba(42,29,23,0.85)",
  cream: "#FDF8F3",
  beige: "#F3E8DC",
  warmGray: "#8B7D73",
  tagAtelier: "#C2553A",
  tagGratuit: "#5A9E6F",
  tagStage: "#D4883E",
  tagEnLigne: "#5B8EC2",
  tagPresetiel: "#C2553A",
  white: "#FFFFFF",
  text: "#3A2E27",
  textLight: "#7A6D63",
};

// ─── Données de test réalistes ─────────────────────────────
const EVENTS = [
  {
    id: 1, date: "2026-03-28", day: "Samedi 28 mars 2026",
    time: "10h00", title: "Danse Intuitive — Écouter son corps",
    instructor: "Marie-Claire Dubois", location: "Studio Harmonie, Paris 11e",
    price: "25€", reducedPrice: "15€", tags: ["Atelier", "En présentiel"],
    img: "https://images.unsplash.com/photo-1508700929628-666bc8bd84ea?w=300&h=200&fit=crop",
    description: "Un atelier pour retrouver le lien entre le mouvement et l'écoute intérieure. Ouvert à tous niveaux.",
    website: "www.marieclaire-danse.fr", email: "contact@marieclaire-danse.fr",
    startTime: "10h00", endTime: "12h00", duration: "2h",
    fullAddress: "12 Rue Oberkampf, 75011 Paris",
  },
  {
    id: 2, date: "2026-03-28", day: "Samedi 28 mars 2026",
    time: "14h30", title: "Contact Improvisation — Jam ouverte",
    instructor: "Thomas Lefèvre", location: "Salle Pina Bausch, Montreuil",
    price: "0€", reducedPrice: null, tags: ["Atelier", "Gratuit", "En présentiel"],
    img: "https://images.unsplash.com/photo-1547153760-18fc86c39dc4?w=300&h=200&fit=crop",
    description: "Jam ouverte de Contact Improvisation. Venez explorer le toucher, le poids et le flux avec d'autres danseurs.",
    website: null, email: "thomas.lefevre@gmail.com",
    startTime: "14h30", endTime: "17h00", duration: "2h30",
    fullAddress: "8 Rue de la Liberté, 93100 Montreuil",
  },
  {
    id: 3, date: "2026-03-28", day: "Samedi 28 mars 2026",
    time: "18h00", title: "5 Rythmes® — Vague du soir",
    instructor: "Sophie Arnaud", location: "Espace Danse Étoile, Paris 20e",
    price: "20€", reducedPrice: "12€", tags: ["Atelier", "En présentiel"],
    img: "https://images.unsplash.com/photo-1518834107812-67b0b7c58434?w=300&h=200&fit=crop",
    description: "Traversez les 5 Rythmes de Gabrielle Roth dans une vague complète. Musique live.",
    website: "www.sophie-5rythmes.fr", email: "sophie@5rythmes.fr",
    startTime: "18h00", endTime: "20h30", duration: "2h30",
    fullAddress: "45 Rue des Pyrénées, 75020 Paris",
  },
  {
    id: 4, date: "2026-03-29", day: "Dimanche 29 mars 2026",
    time: "09h30", title: "Biodanza — Éveil du dimanche",
    instructor: "Stéphane Vernier", location: "Nogent-sur-Marne",
    price: "30€", reducedPrice: "18€", tags: ["Stage", "En présentiel"],
    img: "https://images.unsplash.com/photo-1504609813442-a8924e83f76e?w=300&h=200&fit=crop",
    description: "Stage d'une journée de Biodanza. Reconnexion au vivant par la musique, le mouvement et la rencontre.",
    website: "www.biodanza-stephane.fr", email: "stephane@biodanza.fr",
    startTime: "09h30", endTime: "17h30", duration: "8h",
    fullAddress: "Centre culturel, 94130 Nogent-sur-Marne",
  },
  {
    id: 5, date: "2026-03-29", day: "Dimanche 29 mars 2026",
    time: "10h00", title: "Mouvement Authentique — Cercle en ligne",
    instructor: "Isabelle Moreau", location: "En ligne (Zoom)",
    price: "15€", reducedPrice: null, tags: ["Atelier", "En ligne"],
    img: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=300&h=200&fit=crop",
    description: "Explorez le Mouvement Authentique depuis chez vous. Pratique guidée suivie d'un temps d'écriture et de parole.",
    website: "www.isabelle-mouvement.fr", email: "isabelle.moreau@gmail.com",
    startTime: "10h00", endTime: "12h00", duration: "2h",
    fullAddress: "En ligne — lien envoyé après inscription",
  },
  {
    id: 6, date: "2026-03-29", day: "Dimanche 29 mars 2026",
    time: "15h00", title: "Ecstatic Dance — Session dominicale",
    instructor: "DJ Kaya & Léna Rousseau", location: "La Bellevilloise, Paris 20e",
    price: "18€", reducedPrice: "10€", tags: ["Atelier", "En présentiel"],
    img: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop",
    description: "Ecstatic Dance : dansez librement sur un set live mêlant world music, électro organique et percussions.",
    website: "www.ecstaticdance-paris.fr", email: "hello@ecstaticdance-paris.fr",
    startTime: "15h00", endTime: "18h00", duration: "3h",
    fullAddress: "19-21 Rue Boyer, 75020 Paris",
  },
  {
    id: 7, date: "2026-04-02", day: "Jeudi 2 avril 2026",
    time: "19h30", title: "Open Floor — Danse consciente",
    instructor: "Camille Bertrand", location: "Studio Bleu, Paris 10e",
    price: "22€", reducedPrice: "14€", tags: ["Atelier", "En présentiel"],
    img: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=300&h=200&fit=crop",
    description: "Pratique d'Open Floor : mouvement, présence, expression. Chaque session est unique.",
    website: "www.openfloor-camille.fr", email: "camille@openfloor.fr",
    startTime: "19h30", endTime: "21h30", duration: "2h",
    fullAddress: "33 Rue du Faubourg Saint-Martin, 75010 Paris",
  },
  {
    id: 8, date: "2026-04-04", day: "Samedi 4 avril 2026",
    time: "10h00", title: "La Voie de la Danse — Réveiller sa sensualité",
    instructor: "Duy Dang & Martine Mauricrace", location: "Studio Kim Kan, Paris 20e",
    price: "25€", reducedPrice: "15€", tags: ["Atelier", "Gratuit", "En présentiel"],
    img: "https://images.unsplash.com/photo-1524594152303-9fd13543fe6e?w=300&h=200&fit=crop",
    description: "La sensualité : le plaisir des sens, des sensations. Dans cet atelier nous allons réveiller cette sensualité qui sommeille à l'intérieur de chacun de nous et l'exprimer à travers la danse.",
    website: "www.lavoiedeladanse.fr", email: "bonjour.duy@gmail.com",
    startTime: "10h00", endTime: "12h00", duration: "2h",
    fullAddress: "46 Rue des Rigoles, 75020 Paris",
  },
];

// ─── Tag component ──────────────────────────────────────────
const tagColors = {
  "Atelier": T.tagAtelier,
  "Gratuit": T.tagGratuit,
  "Stage": T.tagStage,
  "En ligne": T.tagEnLigne,
  "En présentiel": T.tagPresetiel,
};

function Tag({ label }) {
  const bg = tagColors[label] || T.warmGray;
  return (
    <span style={{
      display: "inline-block",
      padding: "2px 10px",
      borderRadius: "4px",
      backgroundColor: bg,
      color: T.white,
      fontSize: "11px",
      fontWeight: 600,
      letterSpacing: "0.3px",
      textTransform: "uppercase",
      lineHeight: "18px",
    }}>
      {label}
    </span>
  );
}

// ─── Event Card ─────────────────────────────────────────────
function EventCard({ event, onClick }) {
  const [hovered, setHovered] = useState(false);
  return (
    <div
      onClick={() => onClick(event)}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        display: "flex",
        gap: "16px",
        padding: "14px 0",
        borderBottom: `1px solid ${T.beige}`,
        cursor: "pointer",
        transition: "background 0.2s",
        background: hovered ? "rgba(194,85,58,0.04)" : "transparent",
        borderRadius: "8px",
        marginLeft: "-8px",
        marginRight: "-8px",
        paddingLeft: "8px",
        paddingRight: "8px",
      }}
    >
      {/* Thumbnail */}
      <div style={{
        width: "100px",
        minWidth: "100px",
        height: "80px",
        borderRadius: "8px",
        overflow: "hidden",
        flexShrink: 0,
      }}>
        <img
          src={event.img}
          alt={event.title}
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
          onError={(e) => {
            e.target.style.display = "none";
            e.target.parentElement.style.background = `linear-gradient(135deg, ${T.terracottaPale}, ${T.beige})`;
          }}
        />
      </div>
      {/* Info */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: "6px", flexWrap: "wrap", marginBottom: "4px" }}>
          <span style={{
            fontWeight: 700,
            fontSize: "14px",
            color: T.terracotta,
            fontFamily: "'DM Sans', sans-serif",
          }}>
            {event.time}
          </span>
          {event.tags.map((t) => <Tag key={t} label={t} />)}
        </div>
        <div style={{
          fontWeight: 700,
          fontSize: "15px",
          color: T.text,
          marginBottom: "3px",
          fontFamily: "'DM Sans', sans-serif",
          lineHeight: 1.3,
        }}>
          {event.title}
        </div>
        <div style={{
          fontSize: "13px",
          color: T.textLight,
          fontFamily: "'DM Sans', sans-serif",
        }}>
          Animé par : <span style={{ color: T.terracotta }}>{event.instructor}</span>
        </div>
        <div style={{
          display: "flex",
          alignItems: "center",
          gap: "12px",
          marginTop: "2px",
          fontSize: "13px",
          color: T.textLight,
          fontFamily: "'DM Sans', sans-serif",
        }}>
          <span>📍 {event.location}</span>
          <span style={{ fontWeight: 600, color: T.text }}>
            Prix : {event.price}
          </span>
        </div>
      </div>
    </div>
  );
}

// ─── Event Detail Modal ─────────────────────────────────────
function EventModal({ event, onClose }) {
  if (!event) return null;
  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed", inset: 0,
        background: "rgba(42,29,23,0.6)",
        backdropFilter: "blur(4px)",
        display: "flex", alignItems: "center", justifyContent: "center",
        zIndex: 1000,
        padding: "20px",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: T.white,
          borderRadius: "16px",
          maxWidth: "520px",
          width: "100%",
          maxHeight: "85vh",
          overflow: "auto",
          position: "relative",
          boxShadow: "0 24px 80px rgba(42,29,23,0.25)",
        }}
      >
        {/* Close */}
        <button
          onClick={onClose}
          style={{
            position: "absolute", top: "12px", right: "12px",
            width: "32px", height: "32px",
            borderRadius: "50%",
            background: "rgba(255,255,255,0.9)",
            border: "none",
            cursor: "pointer",
            fontSize: "18px",
            display: "flex", alignItems: "center", justifyContent: "center",
            zIndex: 2,
            boxShadow: "0 2px 8px rgba(0,0,0,0.15)",
            color: T.text,
          }}
        >
          ✕
        </button>

        {/* Tags over image */}
        <div style={{ position: "relative" }}>
          <img
            src={event.img}
            alt={event.title}
            style={{ width: "100%", height: "240px", objectFit: "cover", borderRadius: "16px 16px 0 0" }}
            onError={(e) => {
              e.target.style.display = "none";
              e.target.parentElement.style.background = `linear-gradient(135deg, ${T.terracottaPale}, ${T.beige})`;
              e.target.parentElement.style.height = "200px";
            }}
          />
          <div style={{
            position: "absolute", top: "14px", left: "14px",
            display: "flex", gap: "6px", flexWrap: "wrap",
          }}>
            {event.tags.map((t) => <Tag key={t} label={t} />)}
          </div>
        </div>

        {/* Content */}
        <div style={{ padding: "24px" }}>
          <h2 style={{
            fontFamily: "'Cormorant Garamond', Georgia, serif",
            fontStyle: "italic",
            fontSize: "24px",
            fontWeight: 500,
            color: T.text,
            margin: "0 0 20px 0",
            lineHeight: 1.3,
          }}>
            {event.title}
          </h2>

          <div style={{
            background: T.terracottaPale + "66",
            borderRadius: "12px",
            padding: "16px",
            fontSize: "14px",
            fontFamily: "'DM Sans', sans-serif",
            lineHeight: 1.8,
            color: T.text,
          }}>
            <div>
              <strong>Animé par :</strong>{" "}
              <span style={{ color: T.terracotta }}>{event.instructor}</span>
            </div>
            <div>
              <strong>Début :</strong>{" "}
              <span style={{ color: T.terracotta }}>{event.day.replace(/(Samedi|Dimanche|Jeudi)\s/, "")} {event.startTime}</span>
            </div>
            <div>
              <strong>Fin :</strong>{" "}
              <span style={{ color: T.terracotta }}>{event.day.replace(/(Samedi|Dimanche|Jeudi)\s/, "")} {event.endTime}</span>
            </div>
            <div>
              <strong>Durée :</strong>{" "}
              <span style={{ color: T.terracotta }}>{event.duration}</span>
            </div>
            <div style={{ marginTop: "8px" }}>
              <strong>Où :</strong>{" "}
              <span style={{ color: T.terracotta, textDecoration: "underline", cursor: "pointer" }}>
                {event.location}
              </span>
              <br />
              <span style={{ color: T.terracotta, fontSize: "13px" }}>{event.fullAddress}</span>
            </div>
            <div style={{ marginTop: "8px" }}>
              <strong>Prix normal :</strong>{" "}
              <span style={{ color: T.terracotta, fontWeight: 700 }}>{event.price}</span>
            </div>
            {event.reducedPrice && (
              <div>
                <strong>Prix réduit :</strong>{" "}
                <span style={{ color: T.terracotta, fontWeight: 700 }}>{event.reducedPrice}</span>
              </div>
            )}
            {event.website && (
              <div style={{ marginTop: "6px" }}>
                › <span style={{ color: T.terracotta, textDecoration: "underline", cursor: "pointer" }}>{event.website}</span>
              </div>
            )}
            <div>
              › <span style={{ color: T.terracotta, textDecoration: "underline", cursor: "pointer" }}>{event.email}</span>
            </div>
          </div>

          <div style={{ marginTop: "20px" }}>
            <div style={{
              fontWeight: 700,
              fontSize: "13px",
              textTransform: "uppercase",
              letterSpacing: "1px",
              color: T.terracotta,
              marginBottom: "8px",
              fontFamily: "'DM Sans', sans-serif",
            }}>
              Description :
            </div>
            <p style={{
              fontSize: "14px",
              lineHeight: 1.7,
              color: T.text,
              margin: 0,
              fontFamily: "'DM Sans', sans-serif",
            }}>
              {event.description}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Sidebar ────────────────────────────────────────────────
function FilterSidebar({ filters, setFilters, isMobile, isOpen, onToggle }) {
  const checkboxStyle = (checked) => ({
    width: "18px", height: "18px",
    borderRadius: "4px",
    border: `2px solid ${checked ? T.terracotta : T.warmGray}`,
    background: checked ? T.terracotta : "transparent",
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    cursor: "pointer",
    transition: "all 0.2s",
    flexShrink: 0,
  });

  const CheckBox = ({ label, checked, onChange }) => (
    <label style={{
      display: "flex", alignItems: "center", gap: "8px",
      cursor: "pointer", fontSize: "14px", fontFamily: "'DM Sans', sans-serif",
      color: T.text, fontWeight: 500,
    }}>
      <div style={checkboxStyle(checked)} onClick={onChange}>
        {checked && (
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
            <path d="M2 6L5 9L10 3" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
      </div>
      {label}
    </label>
  );

  const content = (
    <>
      {/* Search */}
      <div style={{
        background: T.terracotta,
        borderRadius: "14px",
        padding: "20px",
        marginBottom: "16px",
      }}>
        <h3 style={{
          fontFamily: "'Cormorant Garamond', Georgia, serif",
          fontStyle: "italic",
          fontSize: "22px",
          fontWeight: 500,
          color: T.white,
          margin: "0 0 12px 0",
        }}>
          Recherchez
        </h3>
        <div style={{
          display: "flex",
          background: T.white,
          borderRadius: "8px",
          overflow: "hidden",
        }}>
          <input
            type="text"
            placeholder="Saisir votre recherche directement"
            style={{
              flex: 1, border: "none", outline: "none",
              padding: "10px 14px",
              fontSize: "13px",
              fontFamily: "'DM Sans', sans-serif",
              color: T.text,
            }}
          />
          <button style={{
            background: "none", border: "none", padding: "0 12px",
            cursor: "pointer", fontSize: "18px", color: T.warmGray,
          }}>
            🔍
          </button>
        </div>
      </div>

      {/* Filters */}
      <div style={{
        background: T.terracotta,
        borderRadius: "14px",
        padding: "20px",
        marginBottom: "16px",
      }}>
        {isMobile && (
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <h3 style={{
              fontFamily: "'Cormorant Garamond', Georgia, serif",
              fontStyle: "italic",
              fontSize: "22px",
              fontWeight: 500,
              color: T.white,
              margin: "0 0 16px 0",
            }}>
              Filtrez l'agenda
            </h3>
            <button onClick={onToggle} style={{
              background: "none", border: "none", color: T.white,
              fontSize: "22px", cursor: "pointer", marginTop: "-16px",
            }}>✕</button>
          </div>
        )}
        {!isMobile && (
          <h3 style={{
            fontFamily: "'Cormorant Garamond', Georgia, serif",
            fontStyle: "italic",
            fontSize: "22px",
            fontWeight: 500,
            color: T.white,
            margin: "0 0 16px 0",
          }}>
            Filtrez l'agenda
          </h3>
        )}
        <div style={{
          background: T.terracottaPale,
          borderRadius: "10px",
          padding: "16px",
        }}>
          <div style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gap: "10px",
            marginBottom: "14px",
          }}>
            <CheckBox label="En présentiel" checked={filters.presentiel} onChange={() => setFilters(f => ({...f, presentiel: !f.presentiel}))} />
            <CheckBox label="Stage" checked={filters.stage} onChange={() => setFilters(f => ({...f, stage: !f.stage}))} />
            <CheckBox label="En ligne" checked={filters.enLigne} onChange={() => setFilters(f => ({...f, enLigne: !f.enLigne}))} />
            <CheckBox label="Gratuit" checked={filters.gratuit} onChange={() => setFilters(f => ({...f, gratuit: !f.gratuit}))} />
          </div>
          <div style={{ marginBottom: "12px" }}>
            <CheckBox label="Atelier" checked={filters.atelier} onChange={() => setFilters(f => ({...f, atelier: !f.atelier}))} />
          </div>

          {/* Date */}
          <div style={{
            display: "flex", alignItems: "center", gap: "10px",
            marginBottom: "10px",
            fontFamily: "'DM Sans', sans-serif",
            fontSize: "13px",
            fontWeight: 600,
            color: T.text,
          }}>
            <span style={{ whiteSpace: "nowrap" }}>À PARTIR DU</span>
            <input type="text" placeholder="JJ/MM/AAAA"
              style={{
                flex: 1, border: `1px solid ${T.warmGray}40`,
                borderRadius: "6px", padding: "7px 10px",
                fontSize: "13px", fontFamily: "'DM Sans', sans-serif",
                background: T.white,
                outline: "none",
              }}
            />
          </div>

          {/* Lieu */}
          <div style={{
            display: "flex", alignItems: "center", gap: "10px",
            marginBottom: "10px",
            fontFamily: "'DM Sans', sans-serif",
            fontSize: "13px",
            fontWeight: 600,
            color: T.text,
          }}>
            <span>LIEU</span>
            <input type="text" placeholder="Adresse, ville ..."
              style={{
                flex: 1, border: `1px solid ${T.warmGray}40`,
                borderRadius: "6px", padding: "7px 10px",
                fontSize: "13px", fontFamily: "'DM Sans', sans-serif",
                background: T.white,
                outline: "none",
              }}
            />
          </div>

          {/* Distance */}
          <div style={{
            display: "flex", alignItems: "center", gap: "10px",
            marginBottom: "16px",
            fontFamily: "'DM Sans', sans-serif",
            fontSize: "13px",
            fontWeight: 600,
            color: T.text,
          }}>
            <span>DISTANCE</span>
            <input type="text" placeholder="km"
              style={{
                width: "60px", border: `1px solid ${T.warmGray}40`,
                borderRadius: "6px", padding: "7px 10px",
                fontSize: "13px", fontFamily: "'DM Sans', sans-serif",
                background: T.white,
                outline: "none",
              }}
            />
          </div>

          <button style={{
            background: T.terracotta,
            color: T.white,
            border: "none",
            borderRadius: "8px",
            padding: "10px 28px",
            fontSize: "14px",
            fontWeight: 600,
            fontFamily: "'DM Sans', sans-serif",
            cursor: "pointer",
            textTransform: "uppercase",
            letterSpacing: "0.5px",
          }}>
            Appliquer
          </button>
        </div>
      </div>

      {/* Newsletter */}
      <div style={{
        background: T.terracotta,
        borderRadius: "14px",
        padding: "20px",
      }}>
        <h3 style={{
          fontFamily: "'Cormorant Garamond', Georgia, serif",
          fontStyle: "italic",
          fontSize: "22px",
          fontWeight: 500,
          color: T.white,
          margin: "0 0 12px 0",
        }}>
          S'inscrire à la newsletter
        </h3>
        <input
          type="email"
          placeholder="Saisir votre mail"
          style={{
            width: "100%",
            border: "none",
            borderRadius: "8px",
            padding: "10px 14px",
            fontSize: "13px",
            fontFamily: "'DM Sans', sans-serif",
            marginBottom: "10px",
            boxSizing: "border-box",
            outline: "none",
          }}
        />
        <button style={{
          background: T.terracottaHover,
          color: T.white,
          border: "none",
          borderRadius: "8px",
          padding: "10px 28px",
          fontSize: "14px",
          fontWeight: 600,
          fontFamily: "'DM Sans', sans-serif",
          cursor: "pointer",
          textTransform: "uppercase",
          letterSpacing: "0.5px",
        }}>
          Souscrire
        </button>
      </div>
    </>
  );

  if (isMobile) {
    return (
      <>
        {/* Toggle button */}
        <button
          onClick={onToggle}
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            width: "100%",
            background: T.terracotta,
            color: T.white,
            border: "none",
            borderRadius: "12px",
            padding: "16px 20px",
            fontFamily: "'Cormorant Garamond', Georgia, serif",
            fontStyle: "italic",
            fontSize: "20px",
            cursor: "pointer",
            marginBottom: isOpen ? "16px" : "24px",
          }}
        >
          <span>Filtrez l'agenda</span>
          <span style={{
            transform: isOpen ? "rotate(180deg)" : "rotate(0deg)",
            transition: "transform 0.3s",
            fontSize: "14px",
          }}>▼</span>
        </button>
        {isOpen && (
          <div style={{
            marginBottom: "24px",
            animation: "slideDown 0.3s ease",
          }}>
            {content}
          </div>
        )}
      </>
    );
  }

  return <div style={{ width: "300px", flexShrink: 0 }}>{content}</div>;
}

// ─── Date Separator ─────────────────────────────────────────
function DateSeparator({ label }) {
  return (
    <div style={{
      fontFamily: "'Cormorant Garamond', Georgia, serif",
      fontStyle: "italic",
      fontSize: "20px",
      fontWeight: 500,
      color: T.text,
      padding: "20px 0 8px 0",
      borderBottom: `2px solid ${T.beige}`,
      marginBottom: "4px",
    }}>
      {label}
    </div>
  );
}

// ─── Main App ───────────────────────────────────────────────
export default function ThreeGracesEventsListing() {
  const [filters, setFilters] = useState({
    presentiel: true, stage: true, enLigne: true, gratuit: true, atelier: true,
  });
  const [selectedEvent, setSelectedEvent] = useState(null);
  const [mobileFiltersOpen, setMobileFiltersOpen] = useState(false);
  const [isMobile, setIsMobile] = useState(window.innerWidth < 860);

  // Responsive listener
  useState(() => {
    const handler = () => setIsMobile(window.innerWidth < 860);
    window.addEventListener("resize", handler);
    return () => window.removeEventListener("resize", handler);
  });

  // Group events by date
  const grouped = EVENTS.reduce((acc, ev) => {
    if (!acc[ev.day]) acc[ev.day] = [];
    acc[ev.day].push(ev);
    return acc;
  }, {});

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,500;0,600;1,400;1,500;1,600&family=DM+Sans:ital,wght@0,400;0,500;0,600;0,700;1,400&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        @keyframes slideDown {
          from { opacity: 0; transform: translateY(-10px); }
          to { opacity: 1; transform: translateY(0); }
        }
        input::placeholder { color: #B0A59A; }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-thumb { background: ${T.terracottaLight}; border-radius: 3px; }
      `}</style>

      <div style={{
        minHeight: "100vh",
        background: T.cream,
        fontFamily: "'DM Sans', sans-serif",
      }}>
        {/* ── Header / Hero ── */}
        <header style={{
          background: `linear-gradient(135deg, ${T.dark} 0%, #3D2B22 100%)`,
          color: T.white,
          padding: isMobile ? "24px 20px" : "32px 48px",
          position: "relative",
          overflow: "hidden",
        }}>
          {/* Subtle texture overlay */}
          <div style={{
            position: "absolute", inset: 0,
            background: "radial-gradient(ellipse at 20% 50%, rgba(194,85,58,0.15) 0%, transparent 60%)",
            pointerEvents: "none",
          }} />

          <div style={{
            maxWidth: "1200px",
            margin: "0 auto",
            position: "relative",
            zIndex: 1,
          }}>
            {/* Logo + Nav */}
            <div style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              marginBottom: "20px",
            }}>
              <div style={{
                fontFamily: "'Cormorant Garamond', Georgia, serif",
                fontStyle: "italic",
                lineHeight: 0.85,
              }}>
                <div style={{ fontSize: isMobile ? "12px" : "14px", letterSpacing: "3px", textTransform: "uppercase", opacity: 0.8 }}>Au Jour</div>
                <div style={{ fontSize: isMobile ? "42px" : "56px", fontWeight: 600 }}>duy</div>
              </div>
              <div style={{ display: "flex", gap: "12px" }}>
                <div style={{
                  width: "36px", height: "36px", borderRadius: "8px",
                  background: "rgba(255,255,255,0.1)", display: "flex",
                  alignItems: "center", justifyContent: "center",
                  cursor: "pointer", fontSize: "18px",
                }}>☰</div>
                <div style={{
                  width: "36px", height: "36px", borderRadius: "8px",
                  background: "rgba(255,255,255,0.1)", display: "flex",
                  alignItems: "center", justifyContent: "center",
                  cursor: "pointer", fontSize: "18px",
                }}>📅</div>
                <div style={{
                  width: "36px", height: "36px", borderRadius: "8px",
                  background: "rgba(255,255,255,0.1)", display: "flex",
                  alignItems: "center", justifyContent: "center",
                  cursor: "pointer", fontSize: "18px",
                }}>📋</div>
              </div>
            </div>

            {/* Tagline */}
            <p style={{
              fontFamily: "'Cormorant Garamond', Georgia, serif",
              fontStyle: "italic",
              fontSize: isMobile ? "15px" : "17px",
              lineHeight: 1.6,
              maxWidth: "680px",
              opacity: 0.9,
              marginBottom: "20px",
            }}>
              Ici c'est l'agenda communautaire des passionnés de danse libre en recherche d'activités 
              d'épanouissement personnel pour faire grandir le corps, ouvrir le cœur, illuminer l'esprit 
              et sublimer l'âme. Donc on y trouve les danses libres et bien plus encore.
            </p>

            {/* CTA Buttons */}
            <div style={{
              display: "flex",
              flexWrap: "wrap",
              gap: "10px",
            }}>
              {[
                { label: "Agenda", bg: T.terracotta },
                { label: "Publies tes ateliers", bg: T.terracottaLight },
                { label: "Actualités", bg: T.terracottaLight },
              ].map(btn => (
                <button key={btn.label} style={{
                  background: btn.bg,
                  color: T.white,
                  border: "none",
                  borderRadius: "8px",
                  padding: "10px 20px",
                  fontSize: "13px",
                  fontWeight: 600,
                  fontFamily: "'DM Sans', sans-serif",
                  cursor: "pointer",
                  textTransform: "uppercase",
                  letterSpacing: "0.3px",
                }}>
                  {btn.label}
                </button>
              ))}
            </div>
            <div style={{
              display: "flex",
              flexWrap: "wrap",
              gap: "10px",
              marginTop: "10px",
            }}>
              {[
                { label: "Qui est Duy", bg: "#6B9E7A" },
                { label: "Me contacter", bg: "#7BA68A" },
                { label: "Donations", bg: "#7BA68A" },
              ].map(btn => (
                <button key={btn.label} style={{
                  background: btn.bg,
                  color: T.white,
                  border: "none",
                  borderRadius: "8px",
                  padding: "10px 20px",
                  fontSize: "13px",
                  fontWeight: 600,
                  fontFamily: "'DM Sans', sans-serif",
                  cursor: "pointer",
                  textTransform: "uppercase",
                  letterSpacing: "0.3px",
                }}>
                  {btn.label}
                </button>
              ))}
            </div>
          </div>
        </header>

        {/* ── Main Content ── */}
        <main style={{
          maxWidth: "1200px",
          margin: "0 auto",
          padding: isMobile ? "24px 16px" : "36px 48px",
          display: "flex",
          gap: "36px",
          alignItems: "flex-start",
        }}>
          {/* Events List */}
          <div style={{ flex: 1, minWidth: 0 }}>
            <h1 style={{
              fontFamily: "'Cormorant Garamond', Georgia, serif",
              fontStyle: "italic",
              fontSize: isMobile ? "28px" : "36px",
              fontWeight: 500,
              color: T.terracotta,
              marginBottom: "8px",
            }}>
              Liste des événements
            </h1>

            {/* Mobile: filter toggle */}
            {isMobile && (
              <FilterSidebar
                filters={filters}
                setFilters={setFilters}
                isMobile={true}
                isOpen={mobileFiltersOpen}
                onToggle={() => setMobileFiltersOpen(!mobileFiltersOpen)}
              />
            )}

            {/* Events grouped by date */}
            {Object.entries(grouped).map(([day, events]) => (
              <div key={day}>
                <DateSeparator label={day} />
                {events.map(ev => (
                  <EventCard
                    key={ev.id}
                    event={ev}
                    onClick={setSelectedEvent}
                  />
                ))}
              </div>
            ))}

            {/* Scroll-to-top hint */}
            <div style={{
              textAlign: "center",
              padding: "32px 0",
              color: T.warmGray,
              fontSize: "13px",
              fontFamily: "'DM Sans', sans-serif",
            }}>
              — Fin des résultats —
            </div>
          </div>

          {/* Desktop Sidebar */}
          {!isMobile && (
            <FilterSidebar
              filters={filters}
              setFilters={setFilters}
              isMobile={false}
              isOpen={true}
              onToggle={() => {}}
            />
          )}
        </main>

        {/* ── Event Detail Modal ── */}
        <EventModal event={selectedEvent} onClose={() => setSelectedEvent(null)} />
      </div>
    </>
  );
}
