export interface Dog {
  id: string;
  name: string;
  breedId: string;
  masteredTrickIds: string[];
}

export function addDog(roster: Dog[], dog: Dog): Dog[] {
  return [...roster, dog];
}

export function recordMastery(roster: Dog[], dogId: string, trickId: string): Dog[] {
  return roster.map(dog => {
    if (dog.id !== dogId) return dog;
    if (dog.masteredTrickIds.includes(trickId)) return dog;
    return { ...dog, masteredTrickIds: [...dog.masteredTrickIds, trickId] };
  });
}

export function repertoire(roster: Dog[], dogId: string): string[] {
  return roster.find(d => d.id === dogId)?.masteredTrickIds ?? [];
}
